#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), './osx-plist/lib') 

require 'pp'
require 'stringio'
require 'osx/plist'

Dir["./amai/pbsync/*.plist"].each do |s|
	buffer = File.open(s).read  
	obj = OSX::PropertyList.load(StringIO.new(buffer), :binary1)[0]
	pp "====", s, obj
end