require 'openssl' 
require 'base64'
require 'stringio'
require 'plist'

# % ruby -ropenssl -e
# 'OpenSSL::PKey::RSA.new(1024).public_key.to_pem.display'
# - -----BEGIN RSA PUBLIC KEY-----
# MIGJAoGBAL8KLG/KSWzi48EMsa6cNlWwXKIrDUjn3dsoWv5fF31J/PUkg0ULw45I
# kBapGw+9iUcfUIOegY80d+WDTO56F0OhLNA4+0huAPfcdVASDnbhyYTn8mQgv2Rf
# qUEvL5+bnacbmN0NVhg9PhljZci2hEFsUDcJP2OX+pbcmXfvnVjbAgMBAAE=
# - -----END RSA PUBLIC KEY-----

root_private_key = OpenSSL::PKey::RSA.new(2048)
host_private_key = OpenSSL::PKey::RSA.new(2048)

b64_s =%Q{
LS0tLS1CRUdJTiBSU0EgUFVCTElDIEtFWS0tLS0tCk1JR0pBb0dCQUtuUUZPR2tBMXZB
cG4rL0srK0ZuMUZWdHl1UGdXMkExU1lPNXBMZEoxcC9USzJ0TVQycXFuZmMKbjVTYjVm
UkFoUi9tL00rYy9XSFd0cFpQSWJGN1VURCtYTFliakwrQ1grQkZzV2xnazNEQ0p6QTJr
Y2ErWnlKeQpGR3VOUDNWN2ZONXdHQXVFMDRNcVMyQ2lFQzlwWHAvZHJhWXZENE1LelBy
anlFSEJ0NlFMQWdNQkFBRT0KLS0tLS1FTkQgUlNBIFBVQkxJQyBLRVktLS0tLQo="
}

pub_key = Base64.decode64(b64_s)

p "pub_key:#{pub_key}"
digest = OpenSSL::Digest::Digest.new("SHA1")

root_ca_cert = OpenSSL::X509::Certificate.new
root_ca_cert.serial = 0
root_ca_cert.not_before = Time.now 
root_ca_cert.not_after = Time.now + 60 * 60 * 24 * 365 * 10
root_ca_cert.public_key = root_private_key.public_key
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
device_cert.sign(root_private_key, digest)

host_cert = OpenSSL::X509::Certificate.new
host_cert.public_key = host_private_key.public_key
host_cert.serial = 0
host_cert.not_before = Time.now 
host_cert.not_after = Time.now + 60 * 60 * 24 * 365 * 10
ef = OpenSSL::X509::ExtensionFactory.new
host_cert.extensions = [
 ef.create_extension("basicConstraints","CA:FALSE", true),
 ef.create_extension("keyUsage","Digital Signature, Key Encipherment", true),
 ]
 
# gnutls_x509_crt_set_key_usage(host_cert, GNUTLS_KEY_KEY_ENCIPHERMENT | GNUTLS_KEY_DIGITAL_SIGNATURE);
host_cert.sign(root_private_key, digest)

root_pem = root_ca_cert.to_pem
device_pem = device_cert.to_pem
host_pem = host_cert.to_pem

root_certificate = StringIO.new(root_pem)
host_certificate = StringIO.new << host_pem 
device_certificate = StringIO.new << device_pem

def rand_hex_3(l)
  "%0#{l}x" % rand(1 << l*4)
end

def rand_digit(l)
  "%0#{l}d" % rand(10 ** l)
end

def gen_hostid
  # [8,4,4,4,12].map {|n| rand_hex_3(n)}.join('-')
  [8,18].map {|n| rand_digit(n)}.join('-')
end

host_id = gen_hostid
p host_id 

certs = {"DeviceCertificate" => root_certificate, 
  "HostCertificate" => device_certificate, 
  "HostID" => host_id,  
  "RootCertificate" => host_certificate}
obj = {"PairRecord"=>certs, "Request" => "Pair" }
p obj.to_plist