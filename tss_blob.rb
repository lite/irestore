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

# tss request 
tssrqst_fn = "./amai/debug/tss-request.plist"
buffer = File.open(tssrqst_fn).read
obj = OSX::PropertyList.load(StringIO.new(buffer), :xml1)[0] 
pp obj 
                                      
obj["@HostPlatformInfo"] = "mac"
obj["@UUID"] = "6D27AA8B-FE93-442D-B957-46BCC347D5FC"
obj["ApECID"] =  86872710412
obj["ApBoardID"] =  0
obj["ApChipID"] =  35104
# uid = "MpFk4Bl7K8JztnfYdU76WDzKs3k=".unpack("m")[0]
# pp uid
uid = Base64.decode64("MpFk4Bl7K8JztnfYdU76WDzKs3k=")
pp uid
uid.blob = true 
obj["UniqueBuildID"] = uid
payload = obj.to_plist(:xml1)  

# http post
uri_gs_serv = "http://gs.apple.com/TSS/controller?action=2"
#uri_gs_serv = "http://cydia.saurik.com/TSS/controller?action=2"
#uri_gs_serv = "http://127.0.0.1:8080/TSS/controller?action=2" 
uri = URI.parse(uri_gs_serv)
req = Net::HTTP::Post.new(uri.path)
req["Content-Type"] = 'text/xml; charset="utf-8"'
req["User-Agent"] = "InetURL/1.0"
req["Proxy-Connection"] = "Keep-Alive"
req["Pragma"] = "no-cache"
req["Content-Length"] = payload.length
# req.basic_auth @user, @pass
res = Net::HTTP.start(uri.host, uri.port) {|http|
  http.request(req, payload)
}    # ===> Success
puts "Response #{res.code} #{res.message}:#{res.body}"                                 
# Response 200 OK:STATUS=94&MESSAGE=This device isn't eligible for the requested build.
													
# keys = ["AppleLogo", "BatteryCharging", "BatteryCharging0", "BatteryCharging1", "BatteryFull", "BatteryLow0", "BatteryLow1", "BatteryPlugin",
# 	"DeviceTree", "KernelCache", "LLB", "RecoveryMode", "RestoreDeviceTree", "RestoreKernelCache", "RestoreLogo", "RestoreRamDisk",  
# 	"iBEC", "iBSS", "iBoot"
# 	]
# 
# obj_digests ={"AppleLogo" => {"Digest" => "w0i+PTyf1tcDgf6rMmYHf4MUxaw=", 
# 	"PartialDigest" => "QAAAAPgUAAA2BheAJyIrNv1oNJXNHDf0nHr0Gw==",
# 	"Trusted" => true}, }
# 
# obj = {
# 	"@APTicket" => true,  "@BBTicket"=> true, "@HostIpAddress"=>"192.168.0.1", "@HostPlatformInfo"=> "windows",
# 	"@UUID"=>"BD95B16E-BCE5-754D-9409-50B774999C15",  "@VersionInfo"=> "libauthinstall-68.1",
# 	"ApBoardID" => 0,  "ApChipID" => 35104,   "ApECID"=> 86872710412, "ApProductionMode"=>true,  "ApSecurityDomain" =>1,
# 	"UniqueBuildID"=> "MpFk4Bl7K8JztnfYdU76WDzKs3k="
# }
# tss response

# patch img3 