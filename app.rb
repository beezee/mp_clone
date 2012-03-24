require 'rubygems' 
require 'sinatra'
require 'uri'
require 'mongo'
require 'base64'
require 'json'
require 'sanitize'

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
  event = Sanitize.clean(params[:event])
  token = Sanitize.clean(params[:token])
  
  result = []
  coll.find({"event" => "#{event}", "properties.token" => "#{token}"}).each {|row| result.push row}
  if not params[:token] == 'chtkmpdemo'
  #TODO: add formal authentication/registration/all that good stuff
    result = {}
    result['status'] = 'failed'
    result['reason'] = 'unauthorized'
  elsif not result.length > 0
    result = {'status' => 'failed', 'reason' => 'No results matched your query', 'query' => "event: #{event}"}
  end
  content_type :json
  result.to_json
end

get '/stats/:token/:event/:property' do
  coll = db.collection MONGO_COLL
  result = []
  event = Sanitize.clean(params[:event])
  property = Sanitize.clean(params[:property])
  token = Sanitize.clean(params[:token])
  coll.find({"event" => "#{event}", "properties.#{property}" => {'$exists' => true}, "properties.token" => "#{token}"}).each {|row| result.push row}
  if not params[:token] == 'chtkmpdemo'
  #TODO: add formal authentication/registration/all that good stuff
    result = {}
    result['status'] = 'failed'
    result['reason'] = 'unauthorized'
  elsif not result.length > 0
    #convert params to strings re: http://www.idontplaydarts.com/2010/07/mongodb-is-vulnerable-to-sql-injection-in-php-at-least/
    result = {'status' => 'failed', 'reason' => 'No results matched your query', 'query' => "event: #{event}, property: #{event}"}
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
    coll = db.collection MONGO_COLL
    #TODO use something more sophisticated to loop through and sanitize data (build ruby-fu)
    clean_properties = {}
    data['properties'].each {|property, value| clean_properties[Sanitize.clean(property)] = Sanitize.clean(value)}
    trackedData = {'event' => Sanitize.clean(data['event']), 'properties' => clean_properties, 'mpclone_time_tracked' => Time.now.to_i}
    coll.insert trackedData
    result['status'] = 'success'
  end
  result.inspect
end
