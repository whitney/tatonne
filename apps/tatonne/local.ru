$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/config"))

# base requirements
require 'rubygems'
require 'sequel'
require 'sinatra'
require 'sinatra/sequel'

# database #
db = {
	:database => 'tatonne_development',
	:encoding => 'utf8',
	:user => 'root',
	:host => 'localhost'
}
DB = Sequel.mysql(db) 

# TODO: memcached #

set :environment, :development

require 'app'
run Sinatra::Application
