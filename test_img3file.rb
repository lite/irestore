#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), '.') 

require 'base64'
require 'img3file'
# unless ARGV.size == 1
#   puts "Usage: #{$0} IMG3_FILE"
#   exit
# end 

base_path = "/Users/dli/ipad/jailbreak/ipsw/dmg"
files = [File.join(base_path,"kernelcache.release.n88")]  

dfu_path = File.join(base_path, "Firmware/dfu/")
files += Dir.glob(File.join(dfu_path,'*.dfu')) 

img3_path = File.join(base_path, "Firmware/all_flash/all_flash.n88ap.production/")
manifest = File.join(img3_path, "manifest") 
p manifest 

# files += Dir.glob(File.join(img3_path,'*.img3')) 

# File.open(manifest).read.split.each do |fname|
File.open(manifest).each_line do |fname|
  files += [File.join(img3_path, fname.strip)]
end 

filename = File.join(img3_path,"applelogo.s5l8920x.img3")    
img3 = Img3File.new
data = File.open(filename,'r').read
img3.parse(StringIO.new(data)) 
pp "===="
pp img3.header 
pp img3.elementkeys

### change the img3 file
p "=========AppleLogo========="
s=%Q{		
		RElDRUAAAAAIAAAADF0EOhQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAAAAAAAAAAAAEhTSFOMAAAAgAAAAEAJpIMSkE78vjuBWzlf
		J4kVmbHteDkapXAyqtRlvQIVuL8v6+AlO/FkH5g7UhjEzTDq5/b2tnpqNtE6
		E5KJ1D/fmmb6i8PI2srPhyqnRh+/eKPAnzHVwL2/faLpu7UAU8LKcP5rAkbk
		h5wY84oFh553rIzdHFXwQ+S9zOthF/jCVFJFQ4EHAAB1BwAAMIID+DCCAuCg
		AwIBAgIBEDANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzETMBEGA1UE
		ChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBB
		dXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMDcwMTA1MTky
		MTU5WhcNMjIwMTA1MTkyMTU5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UEChMK
		QXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRo
		b3JpdHkxMjAwBgNVBAMTKUFwcGxlIFNlY3VyZSBCb290IENlcnRpZmljYXRp
		b24gQXV0aG9yaXR5MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
		/vLd2mU5sHLjA4SB9FbJ0aFKu8gEAfNGDZXhN5UKaUfGxIx5PkdVBrIGFOt+
		pPUj/kI1mO80Bc6a062U0KIPwtK0BEhMI1pbxwudYtPz42sQ/pcIV8YSdncZ
		ssbDLJjttymH5NwYtuXzuhP7sra3Z9nL32+lkz3tepNntP00FuQAqwu3Th9a
		1gNoPnK2FDA6DGSXoEYieRt3LFsukOAR3Baj4cj3hLJP3Es6CtUSftwRP/oR
		c2UaSXCgfnWCtDwrL1XfMIixdU1F3AcoLUo6hf2flT4iupxG97doe7OU1UI+
		BbM4+Gd5SIxsH4u+7u1UBdWjC1h9eA8kqaHcCnTq9wIDAQABo4GcMIGZMA4G
		A1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRJPTZT
		ydcV4YZhTqyrqxhWY13DxjAfBgNVHSMEGDAWgBQr0GlHlHYJ/vRrjS5ApvdH
		TX8IXjA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vd3d3LmFwcGxlLmNvbS9h
		cHBsZWNhL3Jvb3QuY3JsMA0GCSqGSIb3DQEBBQUAA4IBAQA0xQzFDlkRL6bC
		nzJ452QyadutwiXKt0eDt5I8cVOgsq0wlYBQvW1fTNzOeA1MSRBQOBA1v0WB
		rGZYLCEj+JZegOnTxkz9ha45YfYoqkTtFZs/R8BXrGccjM3Uk41P22pUp3tC
		Ww+Zxtc4q1KnoYMdhTB06g0d2miEj+KEfsu5QW7Vn6hCtf8ztnF/6qO53UkD
		YIV2ED6OqOE24xLdhWztZlOwW0ibL3/2yhzwXZgtdK3wSEfF4ZpnsiIPsA4C
		oOG6amK5tLVx9CXhs+Wg7cgaQLX4MRUFpFw4I0yQnUcDgIDUMpBFjw+vm/wC
		7u3L5jH2nxXmfStXQw7iD6GgrYnaMIIDdTCCAl2gAwIBAgICAKQwDQYJKoZI
		hvcNAQEFBQAwfjELMAkGA1UEBhMCVVMxEzARBgNVBAoTCkFwcGxlIEluYy4x
		JjAkBgNVBAsTHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MTIwMAYD
		VQQDEylBcHBsZSBTZWN1cmUgQm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0
		eTAeFw0wOTAzMjUyMDUyNTJaFw0xOTAzMjYyMDUyNTJaMFUxCzAJBgNVBAYT
		AlVTMRMwEQYDVQQKEwpBcHBsZSBJbmMuMQwwCgYDVQQLEwNFVFMxIzAhBgNV
		BAMTGkgyUC1EYXJ3aW4tUHJvZC1EYXRhQ2VudGVyMIGfMA0GCSqGSIb3DQEB
		AQUAA4GNADCBiQKBgQCtTX69O2UddN0JZrGJGJfHCdmsqLBUAt5GZxSKLR/T
		bSmB+v/AargLrpEpVCeQ2UviOtg5a4hKA5PKA9aad17RJbSyhkRqI0PNoigR
		HvYzbehbpcIUjGkREf+8dIP7pk+jjGPawfEqwY36ZORDOGcbMQf//fdbj0HT
		mKlc22HmQwIDAQABo4GpMIGmMAsGA1UdDwQEAwIHgDAdBgNVHQ4EFgQUTdy4
		e14G5dCXeVqt5CCn7QaCw2IwHwYDVR0jBBgwFoAUST02U8nXFeGGYU6sq6sY
		VmNdw8YwVwYKKoZIhvdjZAYBAQEB/wRGBEQzZ21JRAAAADAAAAAAAAAAdHJl
		Y01PRFMQAAAABAAAAAEAAABET1JQEAAAAAQAAAABAAAAUElIQxAAAAAEAAAA
		IIkAADANBgkqhkiG9w0BAQUFAAOCAQEAarQsWZP5f5/QxsAvwvn9Grw92aRo
		jr/eWM8nRozSE9Zmv/Xy+WC9KqIAmViDxvugqv7Y5xKFu3QHdq7fV1NJMowj
		hCpgfMg7x+yyy0rwqqTBGG2a4eH6HK0H5viYz+InOwAIjtaYCtbzH8zc9c1A
		XBLLRiWw4quPfryi6F1ofnMjN1R+VSW38EvqlXNLSaOXCfwffaaAgtlsGUDc
		DuRDWEv3SwDnJ8LphoVn0AOPaykIU2RmWt6GaLsOD6XcmDI3sTJMfZq9XeoL
		7OzEXJW/o2CneFYCQe+9MKz33TloSjZ/3E3YwyQMrCwuhn508AN/qXTnG/G+
		dyHpe+A5I5wcYw==
}  
tmp = Base64.decode64(s)
img3.update_elements(StringIO.new(tmp), tmp.length)
                                          
# s=%Q{		
# 		QAAAAPgUAAA2BheAJyIrNv1oNJXNHDf0nHr0Gw==
# }
# tmp = Base64.decode64(s)
f = File.open("tmp", "wb")
f.write(img3.to_s) 
f.close
###

img3 = Img3File.new 
data = File.open("tmp",'r').read
#pp data
img3.parse(StringIO.new(data))
pp "===="                                    
pp img3.header 
pp img3.elementkeys       

__END__
     
files.each do |filename|
	img3 = Img3File.new
	data = File.open(filename,'r').read
	dir, base = File.split(filename)
	
	img3.parse(StringIO.new(data)) 
  
 	pp "===="
  pp "#{img3.header.image_type.to_s(16).pack("H*")} : #{base}"
	pp img3.header
	pp img3.elements.keys 
                        
end
 
__END__

"===="
"krnl : kernelcache.release.n88"
#<Header signature=1231906611, full_size=5399556, data_size=5399536, shsh_offset=5397432, image_type=1802661484>
["TYPE", "DATA", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"ibec : iBEC.n88ap.RELEASE.dfu"
#<Header signature=1231906611, full_size=158084, data_size=158064, shsh_offset=155960, image_type=1768056163>
["TYPE", "DATA", "VERS", "SEPO", "BORD", "KBAG", "SHSH", "CERT"]
"===="
"ibss : iBSS.n88ap.RELEASE.dfu"
#<Header signature=1231906611, full_size=108932, data_size=108912, shsh_offset=106808, image_type=1768059763>
["TYPE", "DATA", "VERS", "SEPO", "BORD", "KBAG", "SHSH", "CERT"]
"===="
"illb : LLB.n88ap.RELEASE.img3"
#<Header signature=1231906611, full_size=63876, data_size=63856, shsh_offset=61752, image_type=1768713314>
["TYPE", "DATA", "VERS", "SEPO", "BORD", "KBAG", "SHSH", "CERT"]
"===="
"ibot : iBoot.n88ap.RELEASE.img3"
#<Header signature=1231906611, full_size=162180, data_size=162160, shsh_offset=160056, image_type=1768058740>
["TYPE", "DATA", "VERS", "SEPO", "BORD", "KBAG", "SHSH", "CERT"]
"===="
"dtre : DeviceTree.n88ap.img3"
#<Header signature=1231906611, full_size=48836, data_size=48816, shsh_offset=46712, image_type=1685353061>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"logo : applelogo.s5l8920x.img3"
#<Header signature=1231906611, full_size=7492, data_size=7472, shsh_offset=5368, image_type=1819240303>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"recm : recoverymode.s5l8920x.img3"
#<Header signature=1231906611, full_size=39556, data_size=39536, shsh_offset=37432, image_type=1919247213>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"bat0 : batterylow0.s5l8920x.img3"
#<Header signature=1231906611, full_size=47492, data_size=47472, shsh_offset=45368, image_type=1650553904>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"bat1 : batterylow1.s5l8920x.img3"
#<Header signature=1231906611, full_size=17604, data_size=17584, shsh_offset=15480, image_type=1650553905>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"glyC : glyphcharging.s5l8920x.img3"
#<Header signature=1231906611, full_size=6148, data_size=6128, shsh_offset=4024, image_type=1735162179>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"glyP : glyphplugin.s5l8920x.img3"
#<Header signature=1231906611, full_size=5060, data_size=5040, shsh_offset=2936, image_type=1735162192>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"chg0 : batterycharging0.s5l8920x.img3"
#<Header signature=1231906611, full_size=5060, data_size=5040, shsh_offset=2936, image_type=1667786544>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SALT", "SHSH", "CERT"]
"===="
"chg1 : batterycharging1.s5l8920x.img3"
#<Header signature=1231906611, full_size=15940, data_size=15920, shsh_offset=13816, image_type=1667786545>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
"===="
"batF : batteryfull.s5l8920x.img3"
#<Header signature=1231906611, full_size=249860, data_size=249840, shsh_offset=247736, image_type=1650553926>
["TYPE", "DATA", "VERS", "SEPO", "KBAG", "SHSH", "CERT"]
