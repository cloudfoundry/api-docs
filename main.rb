require 'sinatra'
require 'net/http'
require 'open-uri'
require 'json'

def self.load_version_data(file_path)
  JSON.load(File.open(file_path))
end

CF_DEPLOYMENT_VERSIONS = load_version_data('data/cf-deployment-api-versions.json').freeze
CF_RELEASE_VERSIONS = load_version_data('data/cf-release-api-versions.json').freeze

def template
  <<EOS
<html>
<head>
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
  <script src='//code.jquery.com/jquery-2.1.3.js'></script>
  <script src='//maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js'></script>
</head>
<body>
  <%= header %>
  <%= content %>
</body>
</html>
EOS
end

def header_template
  <<EOS
  <div class="btn-group">
    <a class="btn btn-info" href="/<%= current_version %>/"> Home </a>
    <button type='button' class='btn btn-default dropdown-toggle' data-toggle='dropdown' aria-expanded='false'>
        <strong>Version </strong> <%= current_version %> <%= current_cc_api_version %> <span class='caret'></span>
    </button>
    <ul class='dropdown-menu'>
      <%= links %>
      <li class="divider"></li>
      <%= release_candidate_link  %>
    </ul>
  </div>
  <div class="btn-group">
    <a class="btn btn-success" href="http://v3-apidocs.cloudfoundry.org/" target="blank">Version 3</a>
  </div>
EOS
end

def latest_release_num
  list_cf_versions(CF_DEPLOYMENT_VERSIONS).first
end

get '/' do
  # Redirect to latest known docs
  redirect "/#{latest_release_num}/"
end

get '/hello' do
  return "hello #9\n"
end

get %r{/latest-release(/.*)?} do |docs_path|
  redirect "/#{latest_release_num}#{docs_path}"
end

get %r{/release-candidate(/.*)?} do |docs_path|
  s3_base_url = "https://s3.amazonaws.com/cc-api-docs/release-candidate"
  docs_path = "/" unless docs_path

  html_content = fetch_html_from_s3(s3_base_url, docs_path, 'release-candidate')
  modify_html(html_content, docs_path, 'release-candidate')
end

get %r{/(\d[\d\.]+)(/.*)?} do |version, docs_path|
  requested_version = version
  docs_path          = "/" unless docs_path
  html_content       = ''

  if cf_release_version_hash = find_by_cf_version(CF_RELEASE_VERSIONS, requested_version)
    if cf_release_version_hash['BUILD_ID'].nil?
      gh_sha = cf_release_version_hash['CC_SHA']
      gh_base_url  = "https://raw.githubusercontent.com/cloudfoundry/cloud_controller_ng/#{gh_sha}/docs/v2"
      html_content = fetch_html_from_github(gh_base_url, docs_path, requested_version)
    else
      travis_build_id = cf_release_version_hash['BUILD_ID']
      s3_base_url     = "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}"
      html_content    = fetch_html_from_s3(s3_base_url, docs_path, requested_version)
    end
  elsif cf_deployment_version_hash = find_by_cf_version(CF_DEPLOYMENT_VERSIONS, requested_version)
    gh_sha       = cf_deployment_version_hash['CC_SHA']
    gh_base_url  = "https://raw.githubusercontent.com/cloudfoundry/cloud_controller_ng/#{gh_sha}/docs/v2"
    html_content = fetch_html_from_github(gh_base_url, docs_path, requested_version)
  else
    halt 404, erb(template, locals: {
      header: version_links_html(requested_version, docs_path),
      content: "Not Found"
    })
  end

  modify_html(html_content, docs_path, requested_version)
end

def fetch_html_from_github(base_url, docs_path, cf_release_version)
  docs_path = "/index.html" if docs_path == "/"
  url = base_url + docs_path

  begin
    puts "Fetching artifacts from #{url}"
    html_content = URI.parse(url).read
  rescue => e
    if e.message =~ /not found/i
      halt 404, erb(template, locals: {
        header: version_links_html(cf_release_version, docs_path),
        content: "Not Found"
      })
    end
    halt 500, 'Error encountered retrieving API docs.'
  end
  return html_content
end

def fetch_html_from_s3(s3_base_url, docs_path, cf_release_version)
  docs_path = "/index.html" if docs_path == "/"
  s3_url = s3_base_url + docs_path

  begin
    puts "Fetching artifacts from #{s3_url}"
    html_content = URI.parse(s3_url).read
  rescue => e
    if e.message =~ /not found/i
      halt 404, erb(template, locals: {
        header: version_links_html(cf_release_version, docs_path),
        content: "Not Found"
      })
    end
    halt 500, 'Error encountered retrieving API docs.'
  end
  return html_content
end

def modify_html(html_content, docs_path, cf_release_version)
  # change all local HTML links to include cf-release version
  # unless they begin with http
  html_content.gsub!(
    /\bhref=\"(?!http)/,
    "href=\"/#{cf_release_version}/"
  )

  html_body = html_content.gsub(/.*<body>/, '').gsub(/<\/body>.*/, '')
  locals = {
    content: html_body,
    header: version_links_html(cf_release_version, docs_path)
  }

  erb template, locals: locals
end

def version_links_html(current_version, current_path)
  links = (list_cf_versions(CF_DEPLOYMENT_VERSIONS) + list_cf_versions(CF_RELEASE_VERSIONS)).map do |version|
    link_for(version, current_version, current_path)
  end.join(' ')

  locals = {
    links: links,
    release_candidate_link: link_for('release-candidate', current_version, current_path),
    current_version: current_version,
    current_cc_api_version: get_cc_api_version(current_version, true)
  }

  erb header_template, locals: locals
end

def get_cc_api_version(version, bolded = false)
  version_hash = find_by_cf_version(CF_RELEASE_VERSIONS, version) || find_by_cf_version(CF_DEPLOYMENT_VERSIONS, version)

  return '' unless version_hash

  num    = version_hash['CC_API_VERSION']
  prefix = bolded ? '<strong>- CC API VERSION</strong>' : '- CC API VERSION'
  return "#{prefix} #{num}"
end

def find_by_cf_version(version_list, version)
  version_list.find { |version_hash| version_hash['CF_VERSION'] == version }
end

def list_cf_versions(version_list)
  version_list.map { |version_hash| version_hash['CF_VERSION'] }
end

def link_for(version, current_version, current_path)
  cc_api_version = get_cc_api_version(version)
  version == current_version ? "<li><a href='#'> <strong>#{version} #{cc_api_version}</strong> </a></li>" : "<li><a href=\"/#{version}#{current_path}\">#{version} #{cc_api_version}</a></li>"
end
