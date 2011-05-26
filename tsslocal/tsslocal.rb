require "rubygems"
require 'pp'        
require 'sinatra/base'

class TssLocal < Sinatra::Base
  # ... app code here ...
	tssresp_fn = "../amai/debug/tss-response.plist"

	post '/TSS/*' do
		# pp request                           
		# pp request.body.read
	  "MESSAGE=SUCCESS\r\nBODY=#{File.open(tssresp_fn).read}"
	end
	
	get '/TSS/*' do
		# pp request                           
		# pp request.body.read
	  "MESSAGE=SUCCESS\r\nBODY=#{File.open(tssresp_fn).read}"
	end 
  
  # start the server if ruby file executed directly
  run! if app_file == $0
end

# POST /TSS/controller?action=2 HTTP/1.1
# User-Agent: InetURL/1.0
# Host: 127.0.0.1:8080
# Accept: */*
# Content-type: text/xml
# Content-Length: 8190
# Expect: 100-continue
