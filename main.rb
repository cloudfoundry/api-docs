require "sinatra"
require 'net/http'
require "open-uri"
require "json"

BUILD_IDS = {
  207 => 58532799,
  206 => 57530258,
  205 => 55212903,
  204 => 54949372,
  203 => 53876287,
  202 => 53235349,
  201 => 52833659,
  200 => 50698978,
  199 => 50433011,
  198 => 50144686,
  197 => 48526348,
  196 => 47595973,
  195 => 44998082,
  194 => 41997426,
  193 => 40945705,
  192 => 40015178
}

get '/' do
  # Redirect to latest known docs
  redirect "/#{BUILD_IDS.keys.first}/"
end

get %r{/release-candidate(/.*)?} do |docs_path|
  s3_base_url = "https://s3.amazonaws.com/cc-api-docs/release-candidate"
  docs_path = "/" unless docs_path

  html_content = fetch_html_from_s3(s3_base_url, docs_path, 'release-candidate')
  modify_html(html_content, docs_path, 'release-candidate')
end

get %r{/(\d+)(/.*)?} do |version, docs_path|
  cf_release_version = version.to_i rescue nil
  docs_path = "/" unless docs_path

  travis_build_id = BUILD_IDS[cf_release_version]
  s3_base_url = "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}"

  html_content = fetch_html_from_s3(s3_base_url, docs_path, cf_release_version)
  modify_html(html_content, docs_path, cf_release_version)
end

def fetch_html_from_s3(s3_base_url, docs_path, cf_release_version)
  docs_path = "/index.html" if docs_path == "/"
  s3_url = s3_base_url + docs_path

  begin
    puts "Fetching artifacts from #{s3_url}"
    html_content = URI.parse(s3_url).read
  rescue => e
    if e.message =~ /not found/i
      halt 404, "<body>#{version_links_html(cf_release_version, BUILD_IDS.keys, docs_path)}<br/><br/>Not Found</body>"
    end
    halt 500, 'Error encountered retrieving API docs.'
  end
  return html_content
end

def modify_html(html_content, docs_path, cf_release_version)
  # change all local HTML links to include cf-release version
  html_content.gsub!(
    /\bhref=\"\/"/,
    "href=\"/#{cf_release_version}/"
  )
  html_content.sub!(
    '<body>',
    '<body>' + version_links_html(cf_release_version, BUILD_IDS.keys, docs_path)
  )
  html_content
end

def version_links_html(current_version, all_versions, current_path)
  links = all_versions.sort.map do |version|
    link_for(version, current_version, current_path)
  end.join(" ")
  "<p>#{links}</p><br/>#{link_for('release-candidate', current_version, current_path)}"
end

def link_for(version, current_version, current_path)
  version == current_version ? "<strong>#{version}</strong>" : "<a href=\"/#{version}#{current_path}\">#{version}</a>"
end
