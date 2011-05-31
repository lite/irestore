#!/usr/bin/env ruby
# not utf-8

$: << File.join(File.dirname(__FILE__), '.')

require 'iservice'
require 'utils' 
require 'stringio'

class AFCService < DeviceService
  def initialize(port)
    setup
    @socket = open_usbmuxd(port)
    
    @sequence_number = 0
  end
   
	# typedef struct {
	# 	char magic[AFC_MAGIC_LEN];
	# 	uint64_t entire_length, this_length, packet_num, operation;
	# } AFCPacket;
	
	def send_frame(type, data = "", header_size = data.length + 40)
    frame = "CFA6LPAA" + [data.length + 40, 0, header_size, 0, @sequence_number += 1, 0, type, 0].pack("V*") + data
		p "==send_frame=="
    frame.hexdump
    @socket.write(frame)
  end
  
  def recv_frame()
    magic, size = @socket.read(16).unpack("a8V*")
    
    raise "Invalid frame" unless magic == "CFA6LPAA"
    
    header_size = @socket.read(8).unpack("V")[0] # Ignoring other 4 bytes
    sequence_number = @socket.read(8).unpack("V")[0] # Ignoring other 4 bytes

    header_rest = @socket.read(header_size - 32)
		p "==recv_frame=="
		p "header_size:#{header_size}, sequence_number:#{sequence_number}"
		header_rest.hexdump
    
    frame = @socket.read(size - header_size)
		frame.hexdump
    [header_rest, frame]
  end
  
  def ls(path)
    send_frame(3, path + "\x00")  
    recv_frame[1].split("\x00")
  end

  def mkdir(path)
    send_frame(9, path + "\x00")
    recv_frame
  end

  def stat(path)
    send_frame(0xa, path + "\x00")
    Hash[*recv_frame()[1].split("\x00").map{|x| x.to_i.to_s == x ? x.to_i : x}]
  end

  def sysinfo()
    send_frame(0xb)
    Hash[*recv_frame()[1].split("\x00").map{|x| x.to_i.to_s == x ? x.to_i : x}]
  end
  
  # 2 appears to be readable, 3 seems to create the file
  def open(path, mode = 2)
    send_frame(0xd, [mode, 0].pack("V*") + path + "\x00")
    recv_frame[0].unpack("V*")[2] 
  end
  
  def read(handle, file_size)
    send_frame(0xf, [1, 0, file_size, 0].pack("V*"))    
    recv_frame[1]
  end
  
  def write(handle, data)
		send_frame(0x10, [handle, 0].pack("V*") + data, 48)
		recv_frame
  end

	def close(handle)
    send_frame(0x14, [handle, 0].pack("V*"))
		recv_frame
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
    
    afc = AFCService.new(port) 
    #
		puts "sysinfo"
    afc.sysinfo()
    #
		puts "stat"  
    afc.stat("PublicStaging")  
    #
		puts "test-write"
		fpath = File.join("PublicStaging", "test")
		h = afc.open(fpath, 3) 
		io = StringIO.new("a"*(8*1024+99))
		while chunk = io.read(8192-48)
			afc.write(h, chunk)
		end
    afc.close(h)     
		#
		puts "ls"  
    afc.ls("PublicStaging")
		#
		info = afc.stat(fpath)
		pp info 
		#
		puts "test-read"
		h = afc.open(File.join("PublicStaging", "test"), 2) 
		while chunk = afc.read(h, 8*1024-48)
			if chunk.length == 0
				p "file EOF." 
				break
			else
				p chunk.length
			end 
		end
    afc.close(h)     
  end
end

__END__
        
AFC_OP_STATUS          = 0x00000001,	/* Status */
AFC_OP_DATA            = 0x00000002,	/* Data */
AFC_OP_READ_DIR        = 0x00000003,	/* ReadDir */
AFC_OP_READ_FILE       = 0x00000004,	/* ReadFile */
AFC_OP_WRITE_FILE      = 0x00000005,	/* WriteFile */
AFC_OP_WRITE_PART      = 0x00000006,	/* WritePart */
AFC_OP_TRUNCATE        = 0x00000007,	/* TruncateFile */
AFC_OP_REMOVE_PATH     = 0x00000008,	/* RemovePath */
AFC_OP_MAKE_DIR        = 0x00000009,	/* MakeDir */
AFC_OP_GET_FILE_INFO   = 0x0000000a,	/* GetFileInfo */
AFC_OP_GET_DEVINFO     = 0x0000000b,	/* GetDeviceInfo */
AFC_OP_WRITE_FILE_ATOM = 0x0000000c,	/* WriteFileAtomic (tmp file+rename) */
AFC_OP_FILE_OPEN       = 0x0000000d,	/* FileRefOpen */
AFC_OP_FILE_OPEN_RES   = 0x0000000e,	/* FileRefOpenResult */
AFC_OP_READ            = 0x0000000f,	/* FileRefRead */
AFC_OP_WRITE           = 0x00000010,	/* FileRefWrite */
AFC_OP_FILE_SEEK       = 0x00000011,	/* FileRefSeek */
AFC_OP_FILE_TELL       = 0x00000012,	/* FileRefTell */
AFC_OP_FILE_TELL_RES   = 0x00000013,	/* FileRefTellResult */
AFC_OP_FILE_CLOSE      = 0x00000014,	/* FileRefClose */
AFC_OP_FILE_SET_SIZE   = 0x00000015,	/* FileRefSetFileSize (ftruncate) */
AFC_OP_GET_CON_INFO    = 0x00000016,	/* GetConnectionInfo */
AFC_OP_SET_CON_OPTIONS = 0x00000017,	/* SetConnectionOptions */
AFC_OP_RENAME_PATH     = 0x00000018,	/* RenamePath */
AFC_OP_SET_FS_BS       = 0x00000019,	/* SetFSBlockSize (0x800000) */
AFC_OP_SET_SOCKET_BS   = 0x0000001A,	/* SetSocketBlockSize (0x800000) */
AFC_OP_FILE_LOCK       = 0x0000001B,	/* FileRefLock */
AFC_OP_MAKE_LINK       = 0x0000001C,	/* MakeLink */
AFC_OP_SET_FILE_TIME   = 0x0000001E 	/* set st_mtime */

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
