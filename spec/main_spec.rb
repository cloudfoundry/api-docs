require_relative '../main'
require 'json'
require 'rack/test'
require 'webmock/rspec'

describe "Reading Travis Builds API" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:s3_api_docs_content) do
<<EOF
<html>
<body>
  Here are the docs!
</body>
</html>
EOF
  end
  let(:travis_build_id) { 40945705 }
  let(:release_version) { 193 }

  it "redirect from top page / to the latest cf-release" do
    get '/'
    expect(last_response.status).to eq(302)
  end

  it "redirects from /latest-release/doc to the latest final release's version of the doc" do
    get '/latest-release/foobar'
    expect(last_response.status).to eq(302)
    expect(last_response.headers['Location']).to include("/#{BUILD_IDS.keys.max}/foobar")
  end

  it "should pull the latest build for the master branch" do
    stub_request(:get, "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}/index.html")
      .to_return(:body => s3_api_docs_content)

    get "/#{release_version}/"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Here are the docs")
    # link to 192
    expect(last_response.body).to include("192")
    # link to 193
    expect(last_response.body).to include("193")
  end

  it "returns 404 page with links when page does not exist" do
    stub_request(:get, "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}/index.html")
    .to_raise(OpenURI::HTTPError.new("404 Not Found", nil))
    get "/#{release_version}"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to include('Not Found')
    expect(last_response.body).to include("193")
  end
end
