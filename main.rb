require "sinatra"
require 'net/http'
require "open-uri"
require "json"

BUILD_IDS = {
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

get %r{/(\d+)(/.*)?} do |version, docs_path|
  cf_release_version = version.to_i rescue nil
  docs_path = "/" unless docs_path

  travis_build_id = BUILD_IDS[cf_release_version]
  s3_base_url = "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}"
  path = docs_path
  path = "/index.html" if path == "/"
  s3_url = s3_base_url + path

  begin
    html_content = URI.parse(s3_url).read
  rescue => e
    if e.message =~ /not found/i
      halt 404, "<body>#{version_links_html(cf_release_version, BUILD_IDS.keys, docs_path)}Not Found</body>"
    end
    halt 500, 'Error encountered retrieving API docs.'
  end
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
    version == current_version ?
      "<strong>#{version}</strong>" : "<a href=\"/#{version}#{current_path}\">#{version}</a>"
  end.join(" ")
  "<p>#{links}</p>"
end
