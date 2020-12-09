require_relative '../main'
require 'json'
require 'rack/test'
require 'webmock/rspec'

describe 'Api Docs Sinatra App' do
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

  it 'redirect from top page / to the latest cf-release' do
    get '/'
    expect(last_response.status).to eq(302)
  end

  it "redirects from /latest-release/doc to the latest final release's version of the doc" do
    get '/latest-release/foobar'
    expect(last_response.status).to eq(302)

    latest_release_version = CF_DEPLOYMENT_VERSIONS.first['CF_VERSION']
    expect(last_response.headers['Location']).to include("/#{latest_release_version}/foobar")
  end

  it 'should pull the latest build for the main branch' do
    stub_request(:get, "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}/index.html")
      .to_return(:body => s3_api_docs_content)

    get "/#{release_version}/"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include('Here are the docs')
  end

  it 'includes links to docs for other versions from CF Deployment and CF Release' do
    stub_request(:get, "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}/index.html")
      .to_return(:body => s3_api_docs_content)

    get "/#{release_version}/"
    expect(last_response.body).to include('<strong>193 - CC API VERSION 2.18.0</strong> </a></li>')

    expect(last_response.body).to include('<li><a href="/1.23.0/">1.23.0 - CC API VERSION 2.106.0</a></li>')
    expect(last_response.body).to include('<li><a href="/192/">192 - CC API VERSION 2.17.0</a></li>')
  end

  it 'returns 404 page with links when page does not exist' do
    stub_request(:get, "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}/index.html")
    .to_raise(OpenURI::HTTPError.new("404 Not Found", nil))
    get "/#{release_version}"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to include('Not Found')
    expect(last_response.body).to include("193")
  end
end


describe 'find_by_cf_version' do
  let(:subject) {  Sinatra::Application }
  context 'when the specified version exists' do
    let(:versions) do
      JSON.parse(
        '[
          {"CF_VERSION": "287", "CC_SHA": "1429549d039d414fc6a3db82106a83926de28eb4", "CC_API_VERSION": "2.102.0"},
          {"CF_VERSION": "286", "CC_SHA": "dd54fc52174677489b1a976461b54a19821eab32", "CC_API_VERSION": "2.100.0"}
        ]'
      )
    end

    it 'returns the hash for the given version' do
      expect(subject.send(:find_by_cf_version, versions, '286')).to eq(
        'CF_VERSION' => '286', 'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'
      )
    end
  end

  context 'when the specified version does not exist' do
    let(:versions) do
      JSON.parse(
        '[
          {"CF_VERSION": "287", "CC_SHA": "1429549d039d414fc6a3db82106a83926de28eb4", "CC_API_VERSION": "2.102.0"}
        ]'
      )
    end

    it 'returns nil' do
      expect(subject.send(:find_by_cf_version, versions, '286')).to be_nil
    end
  end
end
