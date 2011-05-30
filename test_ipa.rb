#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), '.') 
                  
require 'rubygems'
require 'zip/zipfilesystem'
require 'pp'
    
ipa_path = "./libimobiledevice/tools/ipa/ARCHIVE.ipa"

# pp entry_path

zip_file = Zip::ZipFile.open(ipa_path) 
entry = zip_file.find_entry("*.sinf")
# p entry

Zip::ZipFile.open(ipa_path) {|zipfile| 
	Zip::ZipFile.foreach(ipa_path) do | entry |
		# p entry
		if entry.to_s == "iTunesMetadata.plist"
			puts zipfile.read(entry) 
		elsif entry.to_s =~ /Payload\/.+app\/SC_Info\/.+sinf/
			puts zipfile.read(entry) 
		end
	end
}
