#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), '.') 
$: << File.join(File.dirname(__FILE__), './osx-plist/lib') 

require 'optparse'
require 'net/http'
require 'rexml/document'
require 'pp'   
require 'iservice'
require 'osx/plist'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  
  opts.on("-a", "--activate", "activate the target device") do |a|
    options[:activate] = a
  end
  opts.on("-h", "--help", "show usage") do |h|
    puts opts
    exit
  end
end.parse!

p options

class DeviceActivateRelay <  DeviceRelay
  def activate
    dev = get_value("DeviceClass")
    if (dev == "iPhone")
      uid = get_value("UniqueDeviceID")
      imei = get_value("InternationalMobileEquipmentIdentity")
      iccid = get_value("IntegratedCircuitCardIdentity")
      sn = get_value("SerialNumber")
      imsi = get_value("InternationalMobileSubscriberIdentity")
      activation_info = get_value("ActivationInfo")
    end
    
    p "uid:#{uid} imei:#{imei} iccid:#{iccid} sn:#{sn} imsi:#{imsi}"
    
    p "activation_info:#{activation_info}"
  
    p "fetching activation_record..."
    # url = URI("https://albert.apple.com/WebObjects/ALActivation.woa/wa/iPhoneRegistration")
    url = URI("https://albert.apple.com/WebObjects/ALUnbrick.woa/wa/deviceActivation")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.start do |h|
      req = Net::HTTP::Post.new(url.path, "User-Agent" => "iTunes/9.1 (Macintosh; U; Intel Mac OS X 10.5.6)")
      req.form_data = {
        "AppleSerialNumber" => sn,
        "IMSI" => imsi,
        "InStoreActivation" => "false",
        "machineName" => "macos",
        "activation-info" => activation_info.to_plist,
        "ICCID" => iccid,
        "IMEI" => imei
      }
      #puts req.body
      result = h.request(req)
      puts result.body
      # <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      # <Document xmlns="http://www.apple.com/itms/" disableHistory="true" disableNavigation="true">      
      # <Protocol>
      #     <plist version="1.0">
      #         <dict>
      #           <key>iphone-activation</key>
      #           <dict>
      #             <key>unbrick</key>
      #             <true/>
      #             <key>activation-record</key>
      #             <dict>
      #               <key>DeviceCertificate</key><data>
      xmldoc = REXML::Document.new(result.body)
      buffer = REXML::XPath.first(xmldoc, "//plist").to_s
      # obj = Plist::parse_xml(StringIO.new(buffer))
 			obj = OSX::PropertyList.load(StringIO.new(buffer), :xml1)[0] 
      # "iphone-activation"=>{"show-settings"=>true, "ack-received"=>true} 
			tmp = obj["iphone-activation"]
			if tmp.include?("activation-record")
      	activation_record = tmp["activation-record"]
	      pp activation_record
	      p "activating..."
	      # ssl_enabled
	      obj = {"Request" => "Activate", "ActivationRecord" => activation_record}
	      write_plist(@ssl, obj)
	      read_plist(@ssl) 
 			end
    end
  end
  
  def deactivate
    # ssl_enabled
    obj = {"Request" => "Deactivate"}
    write_plist(@ssl, obj)
    read_plist(@ssl)
  end
end


if __FILE__ == $0
  l = DeviceActivateRelay.new
  
  l.query_type
  
  # pub_key = l.get_value("DevicePublicKey").read
	pub_key = l.get_value("DevicePublicKey")
  p "pub_key:", pub_key
  #
  l.pair_device(pub_key)
  
  # l.validate_pair(pub_key)
  
  @session_id = l.start_session
  p "session_id:", @session_id
  
  # ssl_enable
  l.ssl_enable(true)
  if options[:activate]
    l.activate
  else
    l.deactivate
  end
  l.ssl_enable(false)
  # 
  l.stop_session(@session_id)
end


