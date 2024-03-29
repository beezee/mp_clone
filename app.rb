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
MONGO_COLL = 'mpclone_stats'

get '/' do 
  File.read(File.join('public', 'index.html'))
end

get '/events/:token' do
  coll = db.collection MONGO_COLL
  token = Sanitize.clean params[:token]
  result = coll.find({"properties.token" => "#{token}"}).to_a
  if not params[:token] == 'chtkmpdemo'
  #TODO: add formal authentication/registration/all that good stuff
    result = {}
    result['status'] = 'failed'
    result['reason'] = 'That\'s an invalid api key.'
  elsif not result.length > 0
    result = {'status' => 'failed', 'reason' => 'Looks like we don\'t have any data for you yet!'}
  else
    all_events = result.collect {|x| x['event']}
    result = all_events.uniq.collect {|x| {'val' => x, 'text' => x.to_s.capitalize}}
  end
  content_type :json
  result.to_json
end

get '/properties/:token/:event' do
  coll = db.collection MONGO_COLL
  token = Sanitize.clean params[:token]
  event = Sanitize.clean params[:event]
  result = coll.find({"properties.token" => "#{token}", "event" => "#{event}"}).to_a
  if not params[:token] == 'chtkmpdemo'
  #TODO: add formal authentication/registration/all that good stuff
    result = {}
    result['status'] = 'failed'
    result['reason'] = 'unauthorized'
  elsif not result.length > 0
    result = {'status' => 'failed', 'reason' => 'No results matched your query', 'query' => "event: #{event}"}
  else
    all_props = result.collect {|x| x['properties'].keys}
    content_type :json
    props = all_props.flatten().uniq.reject { |x| x == 'token'}
    result = props.collect {|prop, val| {'val' => prop, 'text' => prop.to_s.capitalize}}
  end
  result.to_json
end

get '/stats/:token/:event/all' do
  #TODO: factor out so this can reuse code from property route
  coll = db.collection MONGO_COLL
  event = Sanitize.clean(params[:event])
  token = Sanitize.clean(params[:token])
  result = coll.find({"event" => "#{event}", "properties.token" => "#{token}"}).sort([['mpclone_time_tracked']]).to_a
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
  event = Sanitize.clean(params[:event])
  property = Sanitize.clean(params[:property])
  token = Sanitize.clean(params[:token])
  result = coll.find({"event" => "#{event}", "properties.#{property}" => {'$exists' => true}, "properties.token" => "#{token}"}).sort([['mpclone_time_tracked']]).to_a
  if not params[:token] == 'chtkmpdemo'
  #TODO: add formal authentication/registration/all that good stuff
    result = {}
    result['status'] = 'failed'
    result['reason'] = 'unauthorized'
  elsif not result.length > 0
    result = {'status' => 'failed', 'reason' => 'No results matched your query', 'query' => "event: #{event}, property: #{event}"}
  end
  content_type :json
  result.to_json
end
  

get '/track/' do
  puts "here"
  puts Base64.decode64 params[:data]
  begin
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
  rescue
    result = {}
    result['status'] = 'failed'
    result['reason'] = 'unallowed characters sent. Please stick to alphanumerics, hyphens and underscores.'
  end
  content_type :json
  result.to_json
end
