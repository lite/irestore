#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), '.')

require 'optparse'
require 'iservice'
require 'utils'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  
  opts.on("-c", "--clean", "clean phonebook") do |s|
    options[:clean] = s
  end
  opts.on("-h", "--help", "show usage") do |h|
    puts opts
    exit
  end
end.parse!

p options
   
EMPTY_PARAMETER_STRING = "___EmptyParameterString___"
MOBILESYNC_DATA_CLASS  = "com.apple.Contacts"
MOBILESYNC_COMPUTER_ANCHOR = "2011-05-25 16:09:37 +0800" 
MOBILESYNC_COMPUTER_CLASS_VERSION = 105

SYNC_TYPES = [
    "SDSyncTypeFast",
    "SDSyncTypeSlow",
    "SDSyncTypeReset"
]
 
class IPBSyncService < DeviceService
  def sync(do_clean) 
    while plist = read_plist(@socket, :binary1) do
			case plist[0] 
			when "DLMessageVersionExchange"
				obj = ["DLMessageVersionExchange", "DLVersionsOk"] 
				write_plist(@socket, obj, :binary1) 
			when "DLMessageDeviceReady"
				obj = ["SDMessageSyncDataClassWithDevice", 
					MOBILESYNC_DATA_CLASS,"---", MOBILESYNC_COMPUTER_ANCHOR, MOBILESYNC_COMPUTER_CLASS_VERSION, EMPTY_PARAMETER_STRING]
				write_plist(@socket, obj, :binary1)
			when "SDMessageSyncDataClassWithComputer"
				pp plist
				obj = ["SDMessageGetAllRecordsFromDevice", MOBILESYNC_DATA_CLASS]
  			write_plist(@socket, obj, :binary1)  
			when "SDMessageProcessChanges"       
				pp plist
				#  {"1"=>
				#    {"display as company"=>"person",
				#     "first name"=>"Hhgg",
				#     "com.apple.syncservices.RecordEntityName"=>"com.apple.contacts.Contact"}},

				#  {"3/1/0"=>
				#    {"value"=>"1 (234) 5",
				#     "com.apple.syncservices.RecordEntityName"=> "com.apple.contacts.Phone Number",
				#     "type"=>"mobile",
				#     "contact"=>["1"]}},
				
				obj = ["SDMessageAcknowledgeChangesFromDevice", MOBILESYNC_DATA_CLASS]
  			write_plist(@socket, obj, :binary1) 
 			when "SDMessageDeviceReadyToReceiveChanges"
				obj = ["DLMessagePing", "Preparing to get changes for device"]
  			write_plist(@socket, obj, :binary1)
          
				if do_clean
					obj = ["SDMessageClearAllRecordsOnDevice", MOBILESYNC_DATA_CLASS, EMPTY_PARAMETER_STRING] 
					write_plist(@socket, obj, :binary1)
				else
					@count = 2
					@uuid = gen_uuid
					@dev_uid = ""
					## create_process_changes_message                                      
					dummy_contact = {@uuid=> 
						{"last name"=>"lite",
				    "title"=>"title",
				    "com.apple.syncservices.RecordEntityName"=>"com.apple.contacts.Contact",
				    "first name"=>"kok"}}
					params ={"SyncDeviceLinkAllRecordsOfPulledEntityTypeSentKey"=>true,
					  "SyncDeviceLinkEntityNamesKey"=>
					   ["com.apple.contacts.Contact", "com.apple.contacts.Group"]}
					obj = ["SDMessageProcessChanges", MOBILESYNC_DATA_CLASS, dummy_contact, true, params] 
					write_plist(@socket, obj, :binary1) 
				end
		 	when "SDMessageDeviceWillClearAllRecords"
				obj = ["SDMessageFinishSessionOnDevice", MOBILESYNC_DATA_CLASS]
			  write_plist(@socket, obj, :binary1)
			when "SDMessageRemapRecordIdentifiers"
				# ["SDMessageRemapRecordIdentifiers", "com.apple.Contacts", {"67E196C3-1439-8442-9AE3-0444C4949EF9"=>"3"}]
				@count -= 1
				if plist[2].include?(@uuid) 
					@dev_uid = plist[2][@uuid]
				end          
				p @dev_uid, @count
				case @count
				when 1              
					local_uid = gen_uuid
					dummy_numbers =  {local_uid =>
					   {"value"=>"1003",
					    "com.apple.syncservices.RecordEntityName"=>
					     "com.apple.contacts.Phone Number",
					    "type"=>"mobile",
					    "contact"=>[@dev_uid]}}
					params = {"SyncDeviceLinkAllRecordsOfPulledEntityTypeSentKey"=>true,
							  "SyncDeviceLinkEntityNamesKey"=>["com.apple.contacts.Phone Number"]}
					obj = ["SDMessageProcessChanges", MOBILESYNC_DATA_CLASS, dummy_numbers, @count==0? true: false , params] 
					write_plist(@socket, obj, :binary1)         
				when 0
					obj = ["SDMessageProcessChanges", MOBILESYNC_DATA_CLASS, {}, @count==0? true: false , params] 
					write_plist(@socket, obj, :binary1)
				else
      		obj = ["SDMessageFinishSessionOnDevice", MOBILESYNC_DATA_CLASS]
				  write_plist(@socket, obj, :binary1)  
				end
			when "SDMessageDeviceFinishedSession"
				obj = ["DLMessageDisconnect", "All done, thanks for the memories"]
				write_plist(@socket, obj, :binary1)   
				p "All done."
				break
			else                                  
				# "SDMessageRefuseToSyncDataClassWithComputer"  
				# "SDMessageCancelSession"
				p "Unknown command"        
				pp plist  
				obj = ["SDMessageCancelSession", MOBILESYNC_DATA_CLASS, "Unknown command"]
        write_plist(@socket, obj, :binary1)
        break
      end
    end
  end
end   
 
if __FILE__ == $0
  l = DeviceRelay.new
  
  l.query_type
  
  pub_key = l.get_value("DevicePublicKey")
  p "pub_key:", pub_key
  #
  l.pair_device(pub_key)
  
  # l.validate_pair(pub_key)
  
  @session_id = l.start_session
  p "session_id:", @session_id
  
  # ssl_enable
  @port = l.start_service(AMSVC_SYNC)
  # 
  l.stop_session(@session_id)
  #
  if @port
    port = @port>>8 | (@port & 0xff)<<8
    
    p = IPBSyncService.new(port)
    p.sync(options[:clean])
  end
end

__END__