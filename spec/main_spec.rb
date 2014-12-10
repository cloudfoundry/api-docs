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

  let(:github_cf_release_src_html) do
<<EOF
    <td class="content">
      <span class="css-truncate css-truncate-target"><a href="/cloudfoundry/cloud_controller_ng" data-skip-pjax="true">cloud_controller_ng</a><span class="ref" title="https://github.com/cloudfoundry/cloud_controller_ng.git @ 670680e3b3e443a06bd04a5cde7b020ba33ff9a1"> @ <a href="/cloudfoundry/cloud_controller_ng/tree/670680e3b3e443a06bd04a5cde7b020ba33ff9a1" data-skip-pjax="true">670680e</a></span></span>
   </td>
EOF
  end

  let(:cc_sha1_for_cf_release_v194) do
    '670680e3b3e443a06bd04a5cde7b020ba33ff9a1'
  end

  describe :cc_sha1 do
    it "should get the sha1 of the cc_ng repo for the given cf-release version" do
      stub_request(:any, "https://github.com/cloudfoundry/cf-release/tree/v194/src")
        .to_return(:body => github_cf_release_src_html)

      expect(cc_sha1(194)).to eq(cc_sha1_for_cf_release_v194)
    end
  end

end
