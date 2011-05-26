require 'optparse'
require File.dirname(__FILE__)+'/iservice'
require File.dirname(__FILE__)+'/utils'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  
  opts.on("-l", "--list", "list files") do |s|
    options[:list] = s
  end
  opts.on("-h", "--help", "show usage") do |h|
    puts opts
    exit
  end
end.parse!

p options    

class AFCService < DeviceService
  def initialize(port)
    setup
    @socket = open_usbmuxd(port)
    
    @sequence_number = 0
  end
  
  def send_frame(type, data = "", header_size = data.length + 40)
    frame = "CFA6LPAA" + [data.length + 40, 0, header_size, 0, @sequence_number += 1, 0, type, 0].pack("V*") + data
    frame.hexdump
    @socket.write(frame)
  end
  
  def recv_frame()
    magic, size = @socket.read(16).unpack("a8V*")
    
    raise "Invalid frame" unless magic == "CFA6LPAA"
    
    header_size = @socket.read(8).unpack("V")[0] # Ignoring other 4 bytes
    sequence_number = @socket.read(8).unpack("V")[0] # Ignoring other 4 bytes

    header_rest = @socket.read(header_size - 32)
    
    frame = @socket.read(size - header_size)
    frame.hexdump
    frame
  end
  
  def sysinfo()
    send_frame(11)
    Hash[*recv_frame().split("\x00").map{|x| x.to_i.to_s == x ? x.to_i : x}]
  end
  
  def stat(path)
    send_frame(10, path + "\x00")
    Hash[*recv_frame().split("\x00").map{|x| x.to_i.to_s == x ? x.to_i : x}]
  end
  
  def mkdir(path)
    send_frame(9, path + "\x00")
    recv_frame()
  end
  
  def ls(path)
    send_frame(3, path + "\x00")  
    recv_frame.split("\x00")
  end
  
  # 2 appears to be readable, 3 seems to create the file
  def open(path, mode = 2)
    send_frame(13, [mode, 0].pack("V*") + path + "\x00")
    recv_frame
  end
  
  def read(file_size)
    send_frame(15, [1, 0, file_size, 0].pack("V*"))    
    recv_frame
  end
  
  def write(data)
    send_frame(16, [1, 0].pack("V*") + data, 48)
  end
end
     
if __FILE__ == $0
  l = DeviceRelay.new
  
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
  @port = l.start_service(AMSVC_AFC)
  # 
  l.stop_session(@session_id)
  #
  if @port
    port = @port>>8 | (@port & 0xff)<<8
    
    p = AFCService.new(port) 
    puts "sysinfo"
    p.sysinfo()
    puts "stat"  
    p.stat("/iTunes_Control")  
    puts "ls"  
    p.ls("/iTunes_Control")
  end
end

__END__

# sysinfo
# 43 46 41 36 4c 50 41 41  28 00 00 00 00 00 00 00  CFA6LPAA(.......
# 28 00 00 00 00 00 00 00  01 00 00 00 00 00 00 00  (...............
# 0b 00 00 00 00 00 00 00                           ........
# 4d 6f 64 65 6c 00 69 50  68 6f 6e 65 32 2c 31 00  Model.iPhone2,1.
# 46 53 54 6f 74 61 6c 42  79 74 65 73 00 31 35 33  FSTotalBytes.153
# 32 36 32 32 34 33 38 34  00 46 53 46 72 65 65 42  26224384.FSFreeB
# 79 74 65 73 00 31 35 32  38 32 38 35 31 38 34 30  ytes.15282851840
# 00 46 53 42 6c 6f 63 6b  53 69 7a 65 00 34 30 39  .FSBlockSize.409
# 36 00                                             6.
#
# stat
# 43 46 41 36 4c 50 41 41  38 00 00 00 00 00 00 00  CFA6LPAA8.......
# 38 00 00 00 00 00 00 00  03 00 00 00 00 00 00 00  8...............
# 0a 00 00 00 00 00 00 00  2f 69 54 75 6e 65 73 5f  ......../iTunes_
# 43 6f 6e 74 72 6f 6c 00                           Control.
# 73 74 5f 73 69 7a 65 00  31 33 36 00 73 74 5f 62  st_size.136.st_b
# 6c 6f 63 6b 73 00 30 00  73 74 5f 6e 6c 69 6e 6b  locks.0.st_nlink
# 00 34 00 73 74 5f 69 66  6d 74 00 53 5f 49 46 44  .4.st_ifmt.S_IFD
# 49 52 00 73 74 5f 6d 74  69 6d 65 00 31 33 30 34  IR.st_mtime.1304
# 37 36 31 38 36 33 30 30  30 30 30 30 30 30 30 00  761863000000000.
# 73 74 5f 62 69 72 74 68  74 69 6d 65 00 31 33 30  st_birthtime.130
# 34 37 35 35 35 38 37 30  30 30 30 30 30 30 30 30  4755587000000000
# 00                                                .
#
# ls
# 43 46 41 36 4c 50 41 41  38 00 00 00 00 00 00 00  CFA6LPAA8.......
# 38 00 00 00 00 00 00 00  04 00 00 00 00 00 00 00  8...............
# 03 00 00 00 00 00 00 00  2f 69 54 75 6e 65 73 5f  ......../iTunes_
# 43 6f 6e 74 72 6f 6c 00                           Control.
# 2e 00 2e 2e 00 4d 75 73  69 63 00 69 54 75 6e 65  .....Music.iTune
# 73 00                                             s.
