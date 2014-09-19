require_relative '../main'
require 'json'
require 'rack/test'
require 'webmock/rspec'

describe "Reading Travis Builds API" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:result) do
<<EOF
    [
      {
        "id": 11111,
        "result": 0,
        "event_type": "push",
        "branch": "wip-dont-publish-me"
      },
      {
        "id": 12345,
        "result": 0,
        "event_type": "push",
        "branch": "master"
      }
    ]
EOF

  end

  it "should pull the latest build for the master branch" do
    stub_request(:any, "https://api.travis-ci.org/repos/cloudfoundry/cloud_controller_ng/builds").to_return(:body => result)

    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("12345")
  end
end
