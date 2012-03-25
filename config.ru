require './app.rb'
require 'rack/timeout'
use Rack::Timeout
run Sinatra::Application