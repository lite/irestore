#!/usr/bin/env ruby 
# encoding: utf-8

$: << File.join(File.dirname(__FILE__), '.')

require 'tsslocal'

run TssLocal

#thin start -p 8080 -R config.ru -D -V

# set :bind, 'localhost'
# set :port, 8080
