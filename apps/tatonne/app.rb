##!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/config"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/lib"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/models"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/views"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/public"))

# require the basic gems needed
# for the sinatra app
require 'rubygems'
require 'sinatra'
require 'active_record'
require 'authlogic'
require 'yaml'
require 'json'
require 'pony'
require 'rack-flash'
#require 'eventmachine'
require 'em-http'

# require some sample helpers
=begin
require 'helpers'

# require some sample middleware
require 'middleware'

use SampleRackMiddleware
=end

use Rack::Flash, :accessorize => [:notice, :error]

set :root, File.dirname(__FILE__)
set :layout, true
set :logging, true
set :sessions, true
set :public, "public"
set :views, "views"

# configure directives can be used to set constants
# that are available in each of your views
configure do
	enable :sessions

	db_config = YAML::load(File.open('config/database.yml'))[Sinatra::Application.environment.to_s]
	ActiveRecord::Base.establish_connection(db_config)

	Version = Sinatra::VERSION
end

# before directives run before all the views
before do
	# make sure mysql has not gone away
	ActiveRecord::Base.verify_active_connections!

	@version = Version
end

# TODO:
# make sure users are logged in unless action is /login or /logout
#before 'not (/login/ or /logout/)' do
#	restrict
#end

# TODO: cleanup helpers
helpers do
	def current_user_session
		return @current_user_session if defined?(@current_user_session)
		@current_user_session = UserSession.find
	end

	def current_user
		return @current_user if defined?(@current_user)
		@current_user = current_user_session && current_user_session.record
	end

	def restrict
		# TODO: use flash notifications
		#(notify 'You must be logged in to view this resource.'; redirect '/login') unless current_user
	end

	def link(name, url)
		"<a href=\"#{url}\">#{name}</a>"
	end
end

['signup_login.rb', 'movies.rb', 'user.rb'].each {|routes_or_classes| load routes_or_classes}

# 404 not found errors
not_found do
	'This is nowhere to be found.'
end

# the other useful default view is for catching 500 server errors
error do
	'Sorry there was a nasty error - ' + request.env['sinatra.error']
end

=begin
# simplest example view we first define a URL route and 
# then return some content to be displayed


# as well as just return body content we can also set
# the HTTP headers directly. This view also demonstrates the use
# of erb templates, with local variables being exposed to the template
get '/index' do
  @page_title = "Title"
  @string = Sample
  erb :index
end

# as well as fixed URLs we can also take named variables
# this view uses a sample helper from the previously loaded
# helpers file
get '/param/:name' do
  bar(params[:name])
end

# splats allow for unnamed wildcard variables in urls
get '/splat/*/*' do
  params["splat"][0] + params["splat"][1]
end

# the redirect method throws a 302 redirect
# and works with local or remote URLs or fragments
get '/home' do
  redirect '/'
end

# if we want to specify the status code for a redirect we can
get '/force' do
  redirect '/', 301
end

# By default views will be served with a 200 status code but 
# you can always overide this if needed
get '/gone' do
  status 410
  "Gone"
end

# sinatra provides a couple of useful defaul views for catching
# 404 not found errors
not_found do
  'This is nowhere to be found'
end

# the other useful default view is for catching 500 server errors
error do
  'Sorry there was a nasty error - ' + request.env['sinatra.error']
end
=end
