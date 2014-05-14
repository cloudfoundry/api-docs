require "sinatra"
require 'net/http'
require "open-uri"
require "json"

get '/' do
 travis = URI.parse("https://api.travis-ci.org/repos/cloudfoundry/cloud_controller_ng/builds").read
 parsed = JSON.parse(travis)
 length = parsed.length
 x = 0
 while x <= length do
  if parsed[x]["result"]==0 && parsed[x]["event_type"]=="push"
    number = parsed[x]["id"]
    break
  end
  x+=1
 end
  "<iframe width=\"100%\" height=\"100%\" src=\"https://s3-us-west-1.amazonaws.com/cc-travis-api-doc/api_docs/#{number}/index.html\" seamless />"
end
