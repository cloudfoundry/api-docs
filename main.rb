require "sinatra"
require 'net/http'
require "open-uri"
require "json"

get '/' do
  begin
    travis = URI.parse("https://api.travis-ci.org/repos/cloudfoundry/cloud_controller_ng/builds").read
    parsed = JSON.parse(travis)
    length = parsed.length
    x = 0
    while x < length do
      if parsed[x]["result"]==0 && parsed[x]["event_type"]=="push" && parsed[x]["branch"] == "master"
        number = parsed[x]["id"]
        break
      end
      x+=1
    end
    "<iframe width=\"100%\" height=\"100%\" src=\"https://s3.amazonaws.com/cc-api-docs/#{number}/index.html\" seamless />"
  rescue => e
    "Error encountered getting latest API doc build number from travis"
  end
end
