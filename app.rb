require 'rubygems' 
require 'sinatra'
require 'uri'
require 'mongo'
require 'base64'
require 'json'

if (ENV['MONGOHQ_URL'])
  uri = URI.parse(ENV['MONGOHQ_URL'])
else uri = URI.parse('mongodb://localhost/mpctest')
end
conn = Mongo::Connection.new(uri.host, uri.port)
db = conn.db(uri.path.gsub(/^\//, ''))
if (ENV['MONGOHQ_URL'])
  db.authenticate(uri.user, uri.password)
end
MONGO_COLL = 'chtkMpClonetest'

get '/' do 
  File.read(File.join('public', 'index.html'))
end

get '/stats/:token/:event' do
  #TODO: factor out so this can reuse code from property route
  coll = db.collection MONGO_COLL
  result = []
  coll.find({"event" => "#{params[:event]}", "properties.token" => "#{params[:token]}"}).each {|row| result.push row}
  if not params[:token] == 'chtkmpdemo'
  #TODO: add formal authentication/registration/all that good stuff
    result = {}
    result['status'] = 'failed'
    result['reason'] = 'unauthorized'
  elsif not result.length > 0
    result = {'status' => 'failed', 'reason' => 'No results matched your query', 'query' => "event #{params[:event]}, property: #{params[:property]}"}
  end
  content_type :json
  result.to_json
end

get '/stats/:token/:event/:property' do
  coll = db.collection MONGO_COLL
  result = []
  coll.find({"event" => "#{params[:event]}", "properties.#{params[:property]}" => {'$exists' => true}, "properties.token" => "#{params[:token]}"}).each {|row| result.push row}
  if not params[:token] == 'chtkmpdemo'
  #TODO: add formal authentication/registration/all that good stuff
    result = {}
    result['status'] = 'failed'
    result['reason'] = 'unauthorized'
  elsif not result.length > 0
    result = {'status' => 'failed', 'reason' => 'No results matched your query', 'query' => "event #{params[:event]}, property: #{params[:property]}"}
  end
  content_type :json
  result.to_json
end
  

get '/track/' do
  puts "here"
  puts Base64.decode64 params[:data]
  data = JSON.parse(Base64.decode64(params[:data].to_s))
  result = {}
  if not data['properties']['token'] == 'chtkmpdemo'
    result['status'] = 'failed'
    result['reason'] = 'unauthorized'
  elsif not data['event']
    result['status'] = 'failed'
    result['reason'] = 'no event provided'
  elsif not data['properties']['ip']
    result['status'] = 'failed'
    result['reason'] = 'no ip provided'
  else
    data['mpclone_time_tracked'] = Time.now.to_i
    coll = db.collection MONGO_COLL
    coll.insert data
    result['status'] = 'success'
  end
  result.inspect
end
