#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), './osx-plist/lib')
                  
require 'rubygems'
require 'pp'
require 'base64'
require 'osx/plist'
require "net/https"
require "uri"
# require 'zip/zipfilesystem'
# require 'fileutils'

# unless ARGV.size == 1
#   puts "Usage: #{$0} IMG3_FILE"
#   exit
# end 

base_path = "/Users/dli/ipad/jailbreak"
ipsw_fn = File.join(base_path, "iPhone2,1_4.3.3_8J2_Restore.ipsw")

dmg_path = "/Users/dli/ipad/jailbreak/ipsw/dmg"

# unzip
# system("mkdir -p #{dmg_path}")
# system("unzip -d #{dmg_path} #{ipsw_fn}")  

# gc-apple-dump_02
if false
	obj = {
		"ECID" 					=> 86872710412,
		"ICCID" 				=> "89860109158380264868",
		"IMEI"					=> "012037007915703",
		"IMSI"					=> "460018445986486",
		"SerialNumber" 	=> "889437758M8"
		}
	payload = obj.to_plist(:xml1)
	
	uri_albert_serv = "https://albert.apple.com/WebObjects/ALUnbrick.woa/wa/ALActivationMonitor/checkUnbrickHealth"
	uri = URI.parse(uri_albert_serv)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	request = Net::HTTP::Post.new(uri.request_uri)
	# cookie:                  NSC_bmvocsjdl_qspe-mc=44cf9618a9dc; mzf_in=061511; Pod=6; s_vnum_us=ch%3Dsafari%26vn%3D1%3Bch%3Dno%20channel%26vn%3D1%3B; s_membership=1%3Ait;                                   
	# s_vi=[CS]v1|26CF8FEF85013DA3-60000107E0075498[CE]                                                                                                                                                         
	request["x-apple-store-front"] = "143465-2,12" 
	request["x-apple-tz"] = "28800"
	request["User-Agent"] = "InetURL/1.0" 
	request["Content-Length"] = payload.length
	request["Content-Type"] = "application/x-apple-plist"
	request.body = payload                    
	response = http.request(request)  
	p response.body 
end

# gc-apple-dump_03
# tss request 
tssrqst_fn = "./amai/debug/tss-request.plist"
payload = File.open(tssrqst_fn).read
# obj = OSX::PropertyList.load(StringIO.new(buffer), :xml1)[0] 
# pp obj 
                                     
# obj["@HostPlatformInfo"] = "mac"
# obj["@UUID"] = "6D27AA8B-FE93-442D-B957-46BCC347D5FC"
# obj["ApECID"] =  86872710412
# obj["ApBoardID"] =  0
# obj["ApChipID"] =  35104
# uid = "MpFk4Bl7K8JztnfYdU76WDzKs3k=".unpack("m")[0]
# pp uid
# uid = Base64.decode64("MpFk4Bl7K8JztnfYdU76WDzKs3k=")
# pp uid
# uid.blob = true 
# obj["UniqueBuildID"] = uid                                                                 
# payload = obj.to_plist(:xml1)                                                              
	            
# http post 
uri_gs_serv = "http://gs.apple.com/TSS/controller?action=2"
#uri_gs_serv = "http://cydia.saurik.com/TSS/controller?action=2"
#uri_gs_serv = "http://127.0.0.1:8080/TSS/controller?action=2" 
uri = URI.parse(uri_gs_serv)
http = Net::HTTP.new(uri.host, uri.port)       
request = Net::HTTP::Post.new(uri.request_uri)
request["User-Agent"] = "InetURL/1.0" 
request["Content-Length"] = payload.length
request["Content-Type"] = 'text/xml; charset="utf-8"'  
request.body = payload                    
response = http.request(request)  
# STATUS=0&MESSAGE=SUCCESS&REQUEST_STRING=
buffer = response.body.split("&REQUEST_STRING=")[1]
obj = OSX::PropertyList.load(StringIO.new(buffer), :xml1)[0] 
pp obj

# patch img3 