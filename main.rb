require "sinatra"
require 'net/http'
require "open-uri"
require "json"

CACHED_BUILD_IDS = {
  #194 => 41997426,
  193 => 40945705,
  192 => 40015178,
  #191 => 38662058, # s3 bucket 404
  #190 => 38069842, # s3 bucket 404
  #189 => 37314314, # s3 bucket 404
}
OLDEST_CF_VERSION = CACHED_BUILD_IDS.keys.min
OLDEST_BUILD_ID = CACHED_BUILD_IDS.values.min
CF_VERSION_COOKIE_NAME = 'cf_release_version'

get '/' do
  # Redirect to latest known docs
  redirect "/#{CACHED_BUILD_IDS.keys.max}/"
end

get %r{/(\d+)(/.*)?} do |version, docs_path|
  cf_release_version = version.to_i rescue nil
  docs_path = "/" unless docs_path
  # The oldest supported one will be hardcoded in the cache
  if cf_release_version.nil?
    halt 400, "Invalid cf-release version given."
  elsif cf_release_version < OLDEST_CF_VERSION
    halt 404, "cf-release versions beyond #{OLDEST_CF_VERSION} not supported (#{cf_release_version} given)."
  else
    travis_build_id = cf_release_travis_build_id cf_release_version
    if travis_build_id.nil?
      halt 404, "Failed to get Travis build id for cf-release v#{cf_release_version}"
    end
    s3_base_url = "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}"
    path = docs_path
    path = "/index.html" if path == "/"
    s3_url = s3_base_url + path
    $stderr.puts "Request: host=#{request.host} version=#{cf_release_version} build=#{travis_build_id} path=#{request.path_info} s3=#{s3_url}"
    begin
      html_content = URI.parse(s3_url).read
    rescue => e
      halt 500, "Error encountered retrieving API docs. #{e.message}"
    end
    # change all local HTML links to include cf-release version
    html_content.gsub!(
      /\bhref=\"\/"/,
      "href=\"/#{cf_release_version}/"
    )
    html_content.sub!(
      '<body>',
      '<body><p>' + version_links_html(cf_release_version, CACHED_BUILD_IDS.keys, docs_path) + '</p>'
    )
    html_content
  end
end

def version_links_html(current_version, all_versions, current_path)
  all_versions.sort.map do |version|
    version == current_version ?
      "<strong>#{version}</strong>" : "<a href=\"/#{version}#{current_path}\">#{version}</a>"
  end.join(" ")
end

def cf_release_cc_sha1 cf_release_version
  begin
    html = URI.parse("https://github.com/cloudfoundry/cf-release/tree/v#{cf_release_version}/src").read
    html =~ /cloud_controller_ng\.git \@ (\w+)/
    $1
  rescue OpenURI::HTTPError => e
    raise unless e.message == "404 Not Found"
    nil
  end
end

def cf_release_travis_build_id cf_release_version
  # Return cached version if possible
  return CACHED_BUILD_IDS[cf_release_version] if CACHED_BUILD_IDS[cf_release_version]

  $stderr.puts "Unknown cf-release version #{cf_release_version}. Discovering..."
  travis_build_id = discovery_build_id_for_cf_version cf_release_version
  if travis_build_id
    $stderr.puts "Found new release build id! #{cf_release_version} => #{travis_build_id} (caching)"
    CACHED_BUILD_IDS[cf_release_version] = travis_build_id
  end
  return travis_build_id
end

def discovery_build_id_for_cf_version cf_release_version
  release_cc_sha1 = cf_release_cc_sha1 cf_release_version
  if release_cc_sha1.nil?
    $stderr.puts "Failed to get cloud_controller_ng commit id for release v#{cf_release_version}."
    return nil
  end
  $stderr.puts "Got cloud_controller_ng.git sha1 for cf-release v#{cf_release_version} => #{release_cc_sha1}"
  last_build_number = nil
  travis_build = nil
  $stderr.puts "Searching through Travis builds for commit:#{release_cc_sha1}"
  while travis_build.nil?
    travis_url = "https://api.travis-ci.org/repos/cloudfoundry/cloud_controller_ng/builds" + (last_build_number.nil? ? "" : "?after_number=#{last_build_number}")
    $stderr.puts "Travis API GET #{travis_url}"
    travis_builds_json = URI.parse(travis_url).read
    travis_builds = JSON.parse(travis_builds_json)
    break unless travis_builds.size > 0
    travis_build = travis_builds.detect { |build| build["commit"] == release_cc_sha1 }
    if travis_build
      $stderr.puts "Found Travis build for commit:#{release_cc_sha1}"
      break
    else
      # We need to get another page of result from Travis API...
      last_build_number = travis_builds.last["number"].to_i
      last_build_id = travis_builds.last["id"].to_i
      if last_build_id < OLDEST_BUILD_ID
        $stderr.puts "Gone back further than old version build number"
        break
      end
    end
  end
  travis_build ? travis_build["id"] : nil
end
