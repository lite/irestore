#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), './osx-plist/lib') 

require 'socket'
require 'openssl'
require 'pp'
require 'stringio'
require 'osx/plist'

#socat -v tcp-l:27015,reuseaddr,fork unix:/var/run/usbmuxd &
$path = "/var/run/usbmuxd"
$tag = 0
$version = 1  

module DeviceSocket
  
  def setup
    # @socket =  UNIXSocket.new($path)
    socket =  TCPSocket.new("127.0.0.1", 27015)

    obj = {"MessageType" => "Listen"}
    data = obj.to_plist
    send_packet(socket, 8, data)
    # send_packet(@socket, 3, "")
    recv_packet(socket)
    # <dict>
    #   <key>DeviceID</key><integer>1</integer>
    #   <dict>
    #   <key>ProductID</key><integer>4756</integer>
    #   <key>SerialNumber</key><string>74f5014572b194c356c8157d6221bd9c84da104c</string>
    #   </dict>
    # </dict>
    p "Please unplug your device, then plug it back in"

    data = recv_packet(socket)[2]    
    # result = Plist::parse_xml(data) 
		result = OSX::PropertyList.load(StringIO.new(data), :xml1)[0]
		# $device_id = result['DeviceID'].to_i  
		pp result
    $device_id = result['DeviceID']
		product_id = result['Properties']['ProductID']
    serial_no = result['Properties']['SerialNumber']

    p $device_id, product_id, serial_no 

    puts "Device ID: 0x#{$device_id.to_s(16)}"
    socket
  end
  
  def open_usbmuxd(port)
    done = false
    $tag = 0
    until done do
      puts "Retrying connection to port #{port}..."

      # @socket = UNIXSocket.new($path)
      # @socket =  TCPSocket.new("127.0.0.1", 27015)
      socket = TCPSocket.new("127.0.0.1", 27015)

      # <dict><key>DeviceID</key><integer>5</integer>
      # <key>MessageType</key><string>Connect</string>
      # <key>PortNumber</key><integer>32498</integer></dict>
      # obj = {"BundleID"=>PLIST_BUNDLE_ID , "ClientVersionString"=>PLIST_CLIENT_VERSION_STRING, "ProgName"=> PLIST_PROGNAME,
      #   "MessageType" => "Connect",  "DeviceID" => @device_id, "PortNumber" => port }
      obj = {"MessageType" => "Connect",  "DeviceID" => $device_id, "PortNumber" => port }
      data = obj.to_plist
      send_packet(socket, 8, data)
      # send_packet(@socket, 2, [@device_id, port, 0].pack("Vnn"))
      data = recv_packet(socket)[2]
      # <dict></dict><key>MessageType</key><string>Result</string><key>Number</key><integer>0</integer>/dict>
      # result = Plist::parse_xml(data)
			result = OSX::PropertyList.load(StringIO.new(data), :xml1)[0]  

      done = result['Number'] == 0
      $tag += 1
      sleep(1)
    end
    puts "Connected to port #{port}"

    socket
  end

  def write_plist(socket, data, fmt=:xml1)
    if data.kind_of?(Hash) || data.kind_of?(Array)
			if fmt == :xml1
	      data = data.to_plist(fmt)  
	    	p "==write_plist==#{data}"
	 		else
				pp "==write_plist==", data
	      data = data.to_plist(fmt)  
			end
    end
    socket.write([data.length].pack("N") + data)
  end
  
  def read_plist(socket, fmt=:xml1)
    buffer = socket.read(4)
    if buffer 
      size = buffer.unpack("N")[0]
      buffer = socket.read(size)
      data = OSX::PropertyList.load(StringIO.new(buffer), fmt)[0]
			if fmt == :xml1
	    	p "==read_plist==#{buffer}"
	 		else
				pp "==read_plist==", data
			end
			return data
    end
  end
    
  def send_packet(socket, packet_type, data)
    packet = [data.length + 16, $version, packet_type, $tag].pack("V4") + data
    p "==send_packet==#{packet}" 
    socket.write(packet)
  end

  def recv_packet(socket)
    header = socket.read(16)
    packet_length, unk, packet_type, tag = header.unpack("V4")
    data = socket.read(packet_length - 16)
    p "==recv_packet==#{data}" 
    [packet_type, tag, data]
  end
end

class DeviceRelay
  
  include DeviceSocket
  
  def initialize
    @root_private_key = OpenSSL::PKey::RSA.new(2048)
    @host_private_key = OpenSSL::PKey::RSA.new(2048)
    @host_id = gen_hostid
    @use_ssl = false
    
    # @socket = UNIXSocket.new($path)
    # @socket =  TCPSocket.new("127.0.0.1", 27015)
    setup
    @socket = open_usbmuxd(32498)
  end
  
  def ssl_enable(use_ssl)
    @use_ssl = use_ssl
  end
  
  def get_value(key="", domain="")
	  obj = {"Request" => "GetValue"}
    obj = obj.merge(key == "" ? {} : {"Key" => key})
    obj = obj.merge(domain == "" ? {} : {"Domain" => domain})
    if @use_ssl
      write_plist(@ssl, obj)
      plist = read_plist(@ssl)
    else
      write_plist(@socket, obj)
      plist = read_plist(@socket)
    end
    # <key>Key</key><string>DevicePublicKey</string>
    # <key>Request</key><string>GetValue</string>
    # <key>Result</key><string>Success</string>
    # <key>Value</key><data>...</data>   
    plist["Value"]
	end
	
  def query_type
    obj = {"ProtocolVersion"=>"2", "Request" => "QueryType" }
    write_plist(@socket, obj)
    read_plist(@socket)
  end
  
  def pair_device(pub_key)
    # 
    @root_ca_cert, @host_cert, @device_cert = gen_cert(pub_key)
    
    root_pem = @root_ca_cert.to_pem 
		device_pem = @device_cert.to_pem
		host_pem = @host_cert.to_pem 
		pub_key.blob = true
		root_pem.blob = true
		device_pem.blob = true    
		host_pem.blob = true
    p "host_id:", @host_id

		# certs = {"DeviceCertificate" => StringIO.new(device_pem), 
		#   "DevicePublicKey" => StringIO.new(pub_key),
		#   "HostCertificate" => StringIO.new(host_pem), 
		#   "HostID" => @host_id,  
		#   "RootCertificate" => StringIO.new(root_pem)
		# } 
	  certs = {"DeviceCertificate" => device_pem, 
	  		  "DevicePublicKey" => pub_key,
	  		  "HostCertificate" => host_pem, 
	  		  "HostID" => @host_id,  
	        "RootCertificate" => root_pem
	        }   
		obj = {"ProtocolVersion"=> "2", "PairRecord"=>certs, "Request" => "Pair" }
    write_plist(@socket, obj)
    read_plist(@socket)
    # <key>EscrowBag</key><data>...</data>
    # <key>Request</key><string>Pair</string>
    # <key>Result</key><string>Success</string>
  end
  
  def validate_pair(pub_key)
    root_pem = @root_ca_cert.to_pem
    device_pem = @device_cert.to_pem
    host_pem = @host_cert.to_pem 
		pub_key.blob = true 
		root_pem.blob = true
		device_pem.blob = true    
		host_pem.blob = true
    p "host_id:", @host_id
    
	  certs = {"DeviceCertificate" => device_pem, 
	  		  "DevicePublicKey" => pub_key,
	  		  "HostCertificate" => host_pem, 
	  		  "HostID" => @host_id,  
	        "RootCertificate" => root_pem
	        }   
 		obj = {"ProtocolVersion" => "2", "PairRecord" => certs, "Request" => "ValidatePair" }
    write_plist(@socket, obj)
    read_plist(@socket)
    # <key>Request</key><string>ValidatePair</string>
    # <key>Result</key><string>Success</string>
   end
  
  def start_session
		obj = {"ProtocolVersion" => "2", "HostID"=>@host_id, "Request" => "StartSession"}
    write_plist(@socket, obj)
    plist = read_plist(@socket)
    # <key>EnableSessionSSL</key><true/>
    # <key>Request</key><string>StartSession</string>
    # <key>Result</key><string>Success</string>
    # <key>SessionID</key><string>C9223F5C-7FEC-4D52-8BA5-11BEC305C7B1</string>
    ctx = OpenSSL::SSL::SSLContext.new(:SSLv3)
    ctx.client_cert_cb = Proc.new{|ssl|
      p "====ctx.client_cert_cb====#{ssl}"
      [@host_cert, @host_private_key]
    }
    # ctx.cert = @host_cert
    # ctx.key = @host_private_key
    # ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    # ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER|OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
    @ssl = OpenSSL::SSL::SSLSocket.new(@socket, ctx)
    @ssl.sync_close = true
    p "connect..."
    @ssl.connect
    
    plist["SessionID"]
  end
  
  def stop_session(session_id)
    obj = {"Request" => "StopSession", "SessionID"=>session_id}
    write_plist(@ssl, obj)
    plist = read_plist(@ssl)
    #goodbye
    goodbye
    @ssl.close
  end
  
  def start_service(serv_name)
    #
    # <key>Request</key><string>StartService</string>
    # <key>Service</key><string>%s</string>
    obj = {"Request"=>"StartService", "Service" => serv_name }
    write_plist(@ssl, obj)
    plist = read_plist(@ssl)
    # <key>Port</key><integer>49791</integer>
    # <key>Request</key><string>StartService</string>
    # <key>Result</key><string>Success</string>
    # <key>Service</key><string>com.apple.afc</string>
    plist["Port"]
  end
  
  def goodbye
    # "<plist><dict><key>Request</key><string>Goodbye</string></dict></plist>\0"
    obj = {"Request" => "Goodbye" }
    write_plist(@socket, obj)
    read_plist(@socket)
  end
  
  def gen_cert(pub_key)
    p "pub_key:#{pub_key}"
    digest = OpenSSL::Digest::Digest.new("SHA1")
    
    root_ca_cert = OpenSSL::X509::Certificate.new
    root_ca_cert.serial = 0
    root_ca_cert.not_before = Time.now 
    root_ca_cert.not_after = Time.now + 60 * 60 * 24 * 365 * 10
    root_ca_cert.public_key = @root_private_key.public_key
    ef = OpenSSL::X509::ExtensionFactory.new
    root_ca_cert.extensions = [
      ef.create_extension("basicConstraints","CA:TRUE", true),
      ]
    
    key = OpenSSL::PKey::RSA.new(pub_key)
    p "modulus:#{key.n}, exponent:#{key.e}"
    
    device_cert = OpenSSL::X509::Certificate.new
    device_cert.public_key = key.public_key
    device_cert.serial = 0
    device_cert.not_before = Time.now 
    device_cert.not_after = Time.now + 60 * 60 * 24 * 365 * 10
    ef = OpenSSL::X509::ExtensionFactory.new
    device_cert.extensions = [
      ef.create_extension("basicConstraints","CA:FALSE", true),
      ef.create_extension("keyUsage","Digital Signature, Key Encipherment", true),
      ]
    device_cert.sign(@root_private_key, digest)

    host_cert = OpenSSL::X509::Certificate.new
    host_cert.public_key = @host_private_key.public_key
    host_cert.serial = 0
    host_cert.not_before = Time.now 
    host_cert.not_after = Time.now + 60 * 60 * 24 * 365 * 10
    ef = OpenSSL::X509::ExtensionFactory.new
    host_cert.extensions = [
      ef.create_extension("basicConstraints","CA:FALSE", true),
      ef.create_extension("keyUsage","Digital Signature, Key Encipherment", true),
      ]
      
    # gnutls_x509_crt_set_key_usage(host_cert, GNUTLS_KEY_KEY_ENCIPHERMENT | GNUTLS_KEY_DIGITAL_SIGNATURE);
    host_cert.sign(@root_private_key, digest)

    [root_ca_cert, host_cert, device_cert]
  end
  
  def rand_digit(l)
    "%0#{l}d" % rand(10 ** l)
  end

  def gen_hostid
    # [8,4,4,4,12].map {|n| rand_hex_3(n)}.join('-')
    [8,18].map {|n| rand_digit(n)}.join('-')
  end
  
end


PORT_RESTORE = 0x7ef2

#   com.apple.mobile.lockdown
#   com.apple.mobile.iTunes
#   com.apple.mobile.battery
#   com.apple.springboard.curvedBatteryCapacity
#   com.apple.mobile.internal
#   com.apple.mobile.debug
#   com.apple.mobile.restriction
#   com.apple.mobile.sync_data_class
#   com.apple.mobile.data_sync
#   com.apple.mobile.nikita
#   com.apple.fairplay
#   com.apple.international
#   com.apple.disk_usage
#   and after xcode has done stuff: com.apple.xcode.developerdomain

AMSVC_AFC                = "com.apple.afc"
AMSVC_BACKUP             = "com.apple.mobilebackup"
AMSVC_CRASH_REPORT_COPY  = "com.apple.crashreportcopy"
AMSVC_DEBUG_IMAGE_MOUNT  = "com.apple.mobile.debug_image_mount"
AMSVC_NOTIFICATION_PROXY = "com.apple.mobile.notification_proxy"
AMSVC_INSTALLATION_PROXY = "com.apple.mobile.installation_proxy"
AMSVC_PURPLE_TEST        = "com.apple.purpletestr"
AMSVC_SOFTWARE_UPDATE    = "com.apple.mobile.software_update"
AMSVC_SYNC               = "com.apple.mobilesync"
AMSVC_SCREENSHOT         = "com.apple.screenshotr"
AMSVC_SYSLOG_RELAY       = "com.apple.syslog_relay"
AMSVC_SYSTEM_PROFILER    = "com.apple.mobile.system_profiler"

class DeviceService
  
  include DeviceSocket
  
  def initialize(port)
    # @socket = UNIXSocket.new($path)
    # @socket =  TCPSocket.new("127.0.0.1", 27015)
    setup
    @socket = open_usbmuxd(port)
  end
end

