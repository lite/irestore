require 'optparse'
require File.dirname(__FILE__)+'/iservice'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  
  opts.on("-r", "--restore", "restore phonebook") do |s|
    options[:restore] = s
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
  
class IPBSyncService < DeviceService
  def sync() 
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

				## clear_all_records_on_device
				obj = ["SDMessageClearAllRecordsOnDevice", MOBILESYNC_DATA_CLASS, EMPTY_PARAMETER_STRING] 
				write_plist(@socket, obj, :binary1)    
			when "SDMessageDeviceWillClearAllRecords"
				pp plist 
				## create_process_changes_message                                      
				dummy_contact = {"12345"=> {"display as company"=>"person",
				"first name"=>"lite","com.apple.syncservices.RecordEntityName"=>"com.apple.contacts.Contact"}}
				# dummy_number = {"3/1/0"=> {"value"=>"1234567", 
				# 	"com.apple.syncservices.RecordEntityName"=> "com.apple.contacts.Phone Number",
				# 	"type"=>"mobile", "contact"=>["12345"]}}
				obj = ["SDMessageProcessChanges", MOBILESYNC_DATA_CLASS, dummy_contact, true, EMPTY_PARAMETER_STRING] 
				# obj = ["SDMessageProcessChanges", MOBILESYNC_DATA_CLASS, dummy_number, false, EMPTY_PARAMETER_STRING] 
				write_plist(@socket, obj, :binary1) 
				# SyncDeviceLinkAllRecordsOfPulledEntityTypeSentKey
				# SyncDeviceLinkEntityNamesKey
			when "SDMessageRemapRecordIdentifiers"
				pp plist
				obj = ["SDMessageFinishSessionOnDevice", MOBILESYNC_DATA_CLASS]
        write_plist(@socket, obj, :binary1) 
      when "SDMessageDeviceFinishedSession"
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
    p.sync
  end
end

__END__