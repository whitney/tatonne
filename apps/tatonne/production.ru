$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/config"))

# base requirements
require 'rubygems'
require 'sinatra'
#require 'yaml'
#require 'active_record'

set :environment, :production

require 'app'
run Sinatra::Application
