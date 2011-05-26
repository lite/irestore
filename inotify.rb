require 'optparse'
require File.dirname(__FILE__)+'/iservice'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  
  opts.on("-f", "--finish", "finish notify") do |s|
    options[:finish] = s
  end
  opts.on("-h", "--help", "show usage") do |h|
    puts opts
    exit
  end
end.parse!

p options

class INotifyService < DeviceService
  def notify(finish)
    if finish
      obj = {"Command"=>"PostNotification", "Name" => "com.apple.itunes-mobdev.syncDidFinish" }
    else
      # "com.apple.itunes-mobdev.syncDidStart"
      obj = {"Command"=>"PostNotification", "Name" => "com.apple.itunes-mobdev.syncWillStart" }
    end
    write_plist(@socket, obj)
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
  @port = l.start_service(AMSVC_NOTIFICATION_PROXY)
  # 
  l.stop_session(@session_id)
  #
  if @port
    port = @port>>8 | (@port & 0xff)<<8
    
    p = INotifyService.new(port)
    if options[:finish]
      p.notify(true)
    else
      p.notify(false)
    end
  end
end

__END__