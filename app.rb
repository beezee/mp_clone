require 'rubygems' 
require 'sinatra'
require 'uri'
require 'mongo'

if (ENV['MONGOHQ_URL'])
  uri = URI.parse(ENV['MONGOHQ_URL'])
else uri = URI.parse('mongodb://localhost/mpctest')
end
conn = Mongo::Connection.new(uri.host, uri.port)
db = conn.db(uri.path.gsub(/^\//, ''))
if (ENV['MONGOHQ_URL'])
  db.authenticate(uri.user, uri.password)
end

get '/' do 
  File.read(File.join('public', 'index.html'))
end

get '/stats/:event/:property' do
  coll = db.collection('testcollection')
  doc = {"event" => params[:event], "property" => params[:property], "value" => "1"}
  coll.insert doc
  result = []
  coll.find({'property' => params[:property]}).each {|row| result.push row.inspect}
  result.inspect
end
  

post '/log/' do
  
end
