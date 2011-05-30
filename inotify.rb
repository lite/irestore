#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), '.')

require 'iservice' 
require 'observer'

NOFITY_TYPE = [ 
	"com.apple.itunes-mobdev.syncWillStart", 
	"com.apple.itunes-mobdev.syncDidStart",  
	"com.apple.itunes-mobdev.syncDidFinish", 
]

class INotifyService < DeviceService 
	include Observable 
	
  def notify(t_notify)
    obj = {"Command"=>"PostNotification", "Name" => t_notify }
    write_plist(@socket, obj)
  end

	def observe(t_event) 
		obj = {"Command"=>"ObserveNotification", "Name" => t_event }
    write_plist(@socket, obj)
	end                        
	
	def run
		lastPrice = nil
    loop do
			obj = read_plist(@socket)
			# {"Command"=>"RelayNotification", "Name"=>"com.apple.mobile.application_uninstalled"}
			if obj.include?("Command") and obj.include?("Name")
				if obj["Command"] == "RelayNotification"
					changed                 # notify observers
					notify_observers(obj["Name"])
				end
			end      
      sleep 1
    end
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
    case ARGV[0]
		when "nofity"
			t_notify = NOFITY_TYPE[ARGV[2].to_i] 
			p.notify(t_notify)
		else 
			t_event = "com.apple.mobile.application_uninstalled"
      p.observe(t_event) 
			p.output
    end
  end
end

__END__