require 'socket'
require 'plist'

class IDevice
  def write_plist(data)
    if data.kind_of?(Hash) || data.kind_of?(Array)
      data = data.to_plist
    end
    p "==write_plist==#{data}" 
    @socket.write([data.length].pack("N") + data)
  end
  
  def read_plist
    buffer = @socket.read(4)
    if buffer 
      size = buffer.unpack("N")[0]
      buffer = @socket.read(size)
      p "==read_plist==#{buffer}" 
      Plist::parse_xml(buffer)
    end
  end
    
  def send_packet(socket, packet_type, data)
    packet = [data.length + 16, @version, packet_type, @tag].pack("V4") + data
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
  
  def initialize(port)
    @tag = 0
    @version = 1
    
    @socket = UNIXSocket.new("/var/run/usbmuxd")
    
    obj = {"MessageType" => "Listen"}
    data = obj.to_plist
    send_packet(@socket, 8, data)
    # send_packet(@socket, 3, "")
    recv_packet(@socket)
    # <dict>
    #   <key>DeviceID</key><integer>1</integer>
    #   <dict>
    #   <key>ProductID</key><integer>4756</integer>
    #   <key>SerialNumber</key><string>74f5014572b194c356c8157d6221bd9c84da104c</string>
    #   </dict>
    # </dict>
    p "Please unplug your device, then plug it back in"
        
    data = recv_packet(@socket)[2]
    result = Plist::parse_xml(data)
    @device_id = result['DeviceID'].to_i
    @product_id = result['Properties']['ProductID']
    @serial_no = result['Properties']['SerialNumber']
    
    p @device_id, @product_id, @serial_no 
    
    @socket.close
      
    puts "Device ID: 0x#{@device_id.to_s(16)}"
      
    @use_ssl = false
      
    done = false
    @tag = 0
    @version = 1
    until done do
      @socket = UNIXSocket.new("/var/run/usbmuxd")
      puts "Retrying connection to port #{port}..."
      
      # <dict><key>DeviceID</key><integer>5</integer>
      # <key>MessageType</key><string>Connect</string>
      # <key>PortNumber</key><integer>32498</integer></dict>
      # obj = {"BundleID"=>PLIST_BUNDLE_ID , "ClientVersionString"=>PLIST_CLIENT_VERSION_STRING, "ProgName"=> PLIST_PROGNAME,
      #   "MessageType" => "Connect",  "DeviceID" => @device_id, "PortNumber" => port }
      obj = {"MessageType" => "Connect",  "DeviceID" => @device_id, "PortNumber" => port }
      data = obj.to_plist
      send_packet(@socket, 8, data)
      # send_packet(@socket, 2, [@device_id, port, 0].pack("Vnn"))
      data = recv_packet(@socket)[2]
      # <dict><key>MessageType</key><string>Result</string><key>Number</key><integer>0</integer>/dict>
      result = Plist::parse_xml(data)
      
      done = result['Number'] == 0
      @socket.close unless done
      @tag += 1
      sleep(1)
    end
    puts "Connected to port #{port}"
  end
  
  def enter_recovery
    # obj = {"ProtocolVersion"=>"2", "Request" => "QueryType" }
    obj = {"Request" => "EnterRecovery" }
    write_plist(obj)
    p read_plist
    
    @socket.close 
  end
  
end

if __FILE__ == $0
  PORT_RESTORE = 0x7ef2
  # PORT_RESTORE = 0xf27e
  d = IDevice.new(PORT_RESTORE)
  
  d.enter_recovery
  
end

# 
# irecovery -c "setenv auto-boot true"
# irecovery -c "saveenv"
# irecovery -c "reboot"
# 
# idevice_id -l | awk -F= '{print "ideviceenterrecovery " $1}' |bash
# # idevice_id -l
# # ideviceenterrecovery -d 39150e1823d53b7c2a8e4ff543881e762392120a 
