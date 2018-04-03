require "sinatra"
require 'net/http'
require "open-uri"
require "json"

CFD_VERSIONS = {
  '1.24.0' => {'CC_SHA' => 'e5e2a6cd5299393686a5eff7c8ebe54d0fd132f1', 'CC_API_VERSION' => '2.107.0'},
  '1.23.0' => {'CC_SHA' => '747dd64af8dbec6e5b3e7fdb5eb0440c9740fab0', 'CC_API_VERSION' => '2.106.0'},
  '1.22.0' => {'CC_SHA' => '747dd64af8dbec6e5b3e7fdb5eb0440c9740fab0', 'CC_API_VERSION' => '2.106.0'},
  '1.21.0' => {'CC_SHA' => '747dd64af8dbec6e5b3e7fdb5eb0440c9740fab0', 'CC_API_VERSION' => '2.106.0'},
  '1.20.0' => {'CC_SHA' => '2b976b1a59b85aaf56d807258e15ec3c8a62c04e', 'CC_API_VERSION' => '2.105.0'},
  '1.19.0' => {'CC_SHA' => '6ef21b06e7c6acfd293b8aafa79646f4e630c5ce', 'CC_API_VERSION' => '2.104.0'},
  '1.18.0' => {'CC_SHA' => '6ef21b06e7c6acfd293b8aafa79646f4e630c5ce', 'CC_API_VERSION' => '2.104.0'},
  '1.17.0' => {'CC_SHA' => '6ef21b06e7c6acfd293b8aafa79646f4e630c5ce', 'CC_API_VERSION' => '2.104.0'},
  '1.16.0' => {'CC_SHA' => 'd362a9b875e27036ba13bf7044a74faf037ab340', 'CC_API_VERSION' => '2.103.0'},
  '1.15.0' => {'CC_SHA' => 'd362a9b875e27036ba13bf7044a74faf037ab340', 'CC_API_VERSION' => '2.103.0'},
  '1.14.0' => {'CC_SHA' => 'd362a9b875e27036ba13bf7044a74faf037ab340', 'CC_API_VERSION' => '2.103.0'},
  '1.13.0' => {'CC_SHA' => 'd362a9b875e27036ba13bf7044a74faf037ab340', 'CC_API_VERSION' => '2.103.0'},
  '1.12.0' => {'CC_SHA' => 'd362a9b875e27036ba13bf7044a74faf037ab340', 'CC_API_VERSION' => '2.103.0'},
  '1.11.0' => {'CC_SHA' => '1429549d039d414fc6a3db82106a83926de28eb4', 'CC_API_VERSION' => '2.102.0'},
  '1.10.0' => {'CC_SHA' => '1429549d039d414fc6a3db82106a83926de28eb4', 'CC_API_VERSION' => '2.102.0'},
  '1.9.0' => {'CC_SHA' => 'c9e54f391005d3871e3b0c697ab03d40ca354e39', 'CC_API_VERSION' => '2.101.0'},
  '1.8.0' => {'CC_SHA' => 'c9e54f391005d3871e3b0c697ab03d40ca354e39', 'CC_API_VERSION' => '2.101.0'},
  '1.7.0' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '1.6.0' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '1.5.0' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '1.4.0' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '1.3.1' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '1.3.0' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '1.2.0' => {'CC_SHA' => '3052dc9fc0bbd0026eae090385b8ad1fba14f2c4', 'CC_API_VERSION' => '2.99.0'},
  '1.1.0' => {'CC_SHA' => '3052dc9fc0bbd0026eae090385b8ad1fba14f2c4', 'CC_API_VERSION' => '2.99.0'},
  '1.0.0' => {'CC_SHA' => '3052dc9fc0bbd0026eae090385b8ad1fba14f2c4', 'CC_API_VERSION' => '2.99.0'},
}

API_VERSIONS = {
  '287' => {'CC_SHA' => '1429549d039d414fc6a3db82106a83926de28eb4', 'CC_API_VERSION' => '2.102.0'},
  '286' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '285' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '284' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '283' => {'CC_SHA' => 'dd54fc52174677489b1a976461b54a19821eab32', 'CC_API_VERSION' => '2.100.0'},
  '282' => {'CC_SHA' => '3052dc9fc0bbd0026eae090385b8ad1fba14f2c4', 'CC_API_VERSION' => '2.99.0'},
  '281' => {'CC_SHA' => '3052dc9fc0bbd0026eae090385b8ad1fba14f2c4', 'CC_API_VERSION' => '2.99.0'},
  '280' => {'CC_SHA' => '3052dc9fc0bbd0026eae090385b8ad1fba14f2c4', 'CC_API_VERSION' => '2.99.0'},
  '279' => {'CC_SHA' => '12ff0ce84071d728649134b018272fc0c656b249', 'CC_API_VERSION' => '2.98.0'},
  '278' => {'CC_SHA' => '12ff0ce84071d728649134b018272fc0c656b249', 'CC_API_VERSION' => '2.98.0'},
  '277' => {'CC_SHA' => '901952357c1e1355f14e2154fa9d088f8ecb2dac', 'CC_API_VERSION' => '2.97.0'},
  '276' => {'CC_SHA' => '901952357c1e1355f14e2154fa9d088f8ecb2dac', 'CC_API_VERSION' => '2.97.0'},
  '275' => {'CC_SHA' => 'e22182ed8ca5db187a523a3d9b341968da99b72e', 'CC_API_VERSION' => '2.96.0'},
  '273' => {'CC_SHA' => 'b7674e074bbb09402e6d0e4f26e8289243cf1faa', 'CC_API_VERSION' => '2.95.0'},
  '272' => {'CC_SHA' => 'b4455bb5ddc24eef3998037e1e8c6becf1afe9cc', 'CC_API_VERSION' => '2.94.0'},
  '271' => {'CC_SHA' => 'b4455bb5ddc24eef3998037e1e8c6becf1afe9cc', 'CC_API_VERSION' => '2.94.0'},
  '270' => {'CC_SHA' => 'd2dbae2838ec0aa8d8b26e8918d4036405177716', 'CC_API_VERSION' => '2.92.0'},
  '269' => {'CC_SHA' => '249e2e8aa1c92f31b1432dac26f24d79197b564d', 'CC_API_VERSION' => '2.90.0'},
  '268' => {'CC_SHA' => 'eeb9c5b3d9b0821fabcc059f0c98167408fedcc5', 'CC_API_VERSION' => '2.89.0'},
  '267' => {'CC_SHA' => '978de5819d21ba18f0e8baa5122af731b376ea5f', 'CC_API_VERSION' => '2.86.0'},
  '266' => {'CC_SHA' => 'c11841b5675aaa47ccd2a70b742eb25601d26d2c', 'CC_API_VERSION' => '2.85.0'},
  '265' => {'CC_SHA' => 'b5491f42fe31d654f05c106496a850ebebe0c555', 'CC_API_VERSION' => '2.84.0'},
  '264' => {'CC_SHA' => 'b5491f42fe31d654f05c106496a850ebebe0c555', 'CC_API_VERSION' => '2.84.0'},
  '263' => {'CC_SHA' => 'b5491f42fe31d654f05c106496a850ebebe0c555', 'CC_API_VERSION' => '2.84.0'},
  '262' => {'CC_SHA' => 'a1b72ee2789ba120465a618361f47c578a5ab2d1', 'CC_API_VERSION' => '2.82.0'},
  '261' => {'CC_SHA' => 'a1b72ee2789ba120465a618361f47c578a5ab2d1', 'CC_API_VERSION' => '2.82.0'},
  '260' => {'CC_SHA' => 'a1b72ee2789ba120465a618361f47c578a5ab2d1', 'CC_API_VERSION' => '2.82.0'},
  '259' => {'CC_SHA' => 'c2d1816117913c5908c1bfcf69aae745b051ad4b', 'CC_API_VERSION' => '2.81.0'},
  '258' => {'CC_SHA' => '663e6e7be7a92d9b9a2b033164ae1b86d3f7396a', 'CC_API_VERSION' => '2.80.0'},
  '257' => {'CC_SHA' => '663e6e7be7a92d9b9a2b033164ae1b86d3f7396a', 'CC_API_VERSION' => '2.80.0'},
  '256' => {'CC_SHA' => '068c65255f733d7c1d2c63d0f31f02cc95b1d6e2', 'CC_API_VERSION' => '2.78.0'},
  '255' => {'CC_SHA' => '068c65255f733d7c1d2c63d0f31f02cc95b1d6e2', 'CC_API_VERSION' => '2.78.0'},
  '254' => {'CC_SHA' => '92e8b1b99eb3a361697316629da36e7a5a19b836', 'CC_API_VERSION' => '2.77.0'},
  '253' => {'CC_SHA' => '3286333334275ff19bc2396fe81f6f3402bc724b', 'CC_API_VERSION' => '2.75.0'},
  '252' => {'CC_SHA' => '169c6ad289b5634ae91db02c01a5794833ee6552', 'CC_API_VERSION' => '2.74.0'},
  '251' => {'CC_SHA' => 'c0be419caf3c4c0bd62253f0c3e70d905dd291b5', 'CC_API_VERSION' => '2.69.0'},
  '250' => {'CC_SHA' => '43b885007cdbbf2fcc81c719bb406b44944fcb31', 'CC_API_VERSION' => '2.68.0'},
  '249' => {'CC_SHA' => '058e366818aba86f8456662b0bba95b0e35846ab', 'CC_API_VERSION' => '2.65.0'},
  '248' => {'CC_SHA' => '058e366818aba86f8456662b0bba95b0e35846ab', 'CC_API_VERSION' => '2.65.0'},
  '247' => {'CC_SHA' => '058e366818aba86f8456662b0bba95b0e35846ab', 'CC_API_VERSION' => '2.65.0'},
  '246' => {'CC_SHA' => '654e39c6d22f99e75ba0833236c5e6a3f12ad967', 'CC_API_VERSION' => '2.64.0'},
  '245' => {'CC_SHA' => '1077b959f9472a5614f44739cdf130b16ca12a81', 'CC_API_VERSION' => '2.63.0'},
  '244' => {'CC_SHA' => 'a79b5588345bac8f1f2f7d05e06c05ef8666bb0c', 'CC_API_VERSION' => '2.62.0'},
  '243' => {'CC_SHA' => 'a79b5588345bac8f1f2f7d05e06c05ef8666bb0c', 'CC_API_VERSION' => '2.62.0'},
  '242' => {'CC_SHA' => 'a79b5588345bac8f1f2f7d05e06c05ef8666bb0c', 'CC_API_VERSION' => '2.62.0'},
  '241' => {'CC_SHA' => '5e6568ba01431aeb3f52a8e654cfc82ff539b622', 'CC_API_VERSION' => '2.61.0'},
  '240' => {'CC_SHA' => 'b41a8295bc7ef7c70cadce77acaf4fe7d3627672', 'CC_API_VERSION' => '2.59.0'},
  '239' => {'CC_SHA' => '65961a953b9ffd5b1b3c0717a6b7a403748ba988', 'CC_API_VERSION' => '2.58.0'},
  '238' => {'CC_SHA' => '2157be5c9c56d46649c61441f552c30d268332aa', 'CC_API_VERSION' => '2.57.0'},
  '237' => {'BUILD_ID' => 129583505, 'CC_API_VERSION' => '2.56.0'},
  '236' => {'BUILD_ID' => 125103468, 'CC_API_VERSION' => '2.55.0'},
  '235' => {'BUILD_ID' => 123491350, 'CC_API_VERSION' => '2.54.0'},
  '234' => {'BUILD_ID' => 121031369, 'CC_API_VERSION' => '2.53.0'},
  '233' => {'BUILD_ID' => 116758428, 'CC_API_VERSION' => '2.52.0'},
  '232' => {'BUILD_ID' => 115991017, 'CC_API_VERSION' => '2.52.0'},
  '231' => {'BUILD_ID' => 110284023, 'CC_API_VERSION' => '2.51.0'},
  '230' => {'BUILD_ID' => 105020109, 'CC_API_VERSION' => '2.48.0'},
  '229' => {'BUILD_ID' => 103428675, 'CC_API_VERSION' => '2.47.0'},
  '228' => {'BUILD_ID' => 102155078, 'CC_API_VERSION' => '2.47.0'},
  '227' => {'BUILD_ID' => 98370576, 'CC_API_VERSION' => '2.46.0'},
  '226' => {'BUILD_ID' => 94057175, 'CC_API_VERSION' => '2.44.0'},
  '225' => {'BUILD_ID' => 90981793, 'CC_API_VERSION' => '2.43.0'},
  '224' => {'BUILD_ID' => 88916778, 'CC_API_VERSION' => '2.42.0'},
  '223' => {'BUILD_ID' => 88916778, 'CC_API_VERSION' => '2.42.0'},
  '222' => {'BUILD_ID' => 85641576, 'CC_API_VERSION' => '2.41.0'},
  '221' => {'BUILD_ID' => 85167498, 'CC_API_VERSION' => '2.40.0'},
  '220' => {'BUILD_ID' => 84006459, 'CC_API_VERSION' => '2.39.0'},
  '219' => {'BUILD_ID' => 83029259, 'CC_API_VERSION' => '2.37.0'},
  '218' => {'BUILD_ID' => 79900811, 'CC_API_VERSION' => '2.36.0'},
  '217' => {'BUILD_ID' => 78125812, 'CC_API_VERSION' => '2.35.0'},
  '215' => {'BUILD_ID' => 74335342, 'CC_API_VERSION' => '2.34.0'},
  '214' => {'BUILD_ID' => 72920095, 'CC_API_VERSION' => '2.33.0'},
  '213' => {'BUILD_ID' => 69811325, 'CC_API_VERSION' => '2.33.0'},
  '212' => {'BUILD_ID' => 67117720, 'CC_API_VERSION' => '2.29.0'},
  '211' => {'BUILD_ID' => 65314847, 'CC_API_VERSION' => '2.28.0'},
  '210' => {'BUILD_ID' => 63419982, 'CC_API_VERSION' => '2.27.0'},
  '209' => {'BUILD_ID' => 62731063, 'CC_API_VERSION' => '2.27.0'},
  '208' => {'BUILD_ID' => 61698265, 'CC_API_VERSION' => '2.25.0'},
  '207' => {'BUILD_ID' => 58532799, 'CC_API_VERSION' => '2.25.0'},
  '206' => {'BUILD_ID' => 57530258, 'CC_API_VERSION' => '2.24.0'},
  '205' => {'BUILD_ID' => 55212903, 'CC_API_VERSION' => '2.23.0'},
  '204' => {'BUILD_ID' => 54949372, 'CC_API_VERSION' => '2.23.0'},
  '203' => {'BUILD_ID' => 53876287, 'CC_API_VERSION' => '2.23.0'},
  '202' => {'BUILD_ID' => 53235349, 'CC_API_VERSION' => '2.22.0'},
  '201' => {'BUILD_ID' => 52833659, 'CC_API_VERSION' => '2.22.0'},
  '200' => {'BUILD_ID' => 50698978, 'CC_API_VERSION' => '2.22.0'},
  '199' => {'BUILD_ID' => 50433011, 'CC_API_VERSION' => '2.22.0'},
  '198' => {'BUILD_ID' => 50144686, 'CC_API_VERSION' => '2.22.0'},
  '197' => {'BUILD_ID' => 48526348, 'CC_API_VERSION' => '2.21.0'},
  '196' => {'BUILD_ID' => 47595973, 'CC_API_VERSION' => '2.21.0'},
  '195' => {'BUILD_ID' => 44998082, 'CC_API_VERSION' => '2.19.0'},
  '194' => {'BUILD_ID' => 41997426, 'CC_API_VERSION' => '2.18.0'},
  '193' => {'BUILD_ID' => 40945705, 'CC_API_VERSION' => '2.18.0'},
  '192' => {'BUILD_ID' => 40015178, 'CC_API_VERSION' => '2.17.0'}
}

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
  CFD_VERSIONS.keys.first
end

get '/' do
  # Redirect to latest known docs
  redirect "/#{latest_release_num}/"
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
  cf_release_version = version
  docs_path          = "/" unless docs_path
  html_content       = ''

  if API_VERSIONS.has_key?(cf_release_version)
    if API_VERSIONS[cf_release_version]["BUILD_ID"].nil?
      gh_sha = API_VERSIONS[cf_release_version]["CC_SHA"]
      gh_base_url  = "https://raw.githubusercontent.com/cloudfoundry/cloud_controller_ng/#{gh_sha}/docs/v2"
      html_content = fetch_html_from_github(gh_base_url, docs_path, cf_release_version)
    else
      travis_build_id = API_VERSIONS[cf_release_version]["BUILD_ID"]
      s3_base_url     = "https://s3.amazonaws.com/cc-api-docs/#{travis_build_id}"
      html_content    = fetch_html_from_s3(s3_base_url, docs_path, cf_release_version)
    end
  elsif CFD_VERSIONS.has_key?(cf_release_version)
    gh_sha       = CFD_VERSIONS[cf_release_version]["CC_SHA"]
    gh_base_url  = "https://raw.githubusercontent.com/cloudfoundry/cloud_controller_ng/#{gh_sha}/docs/v2"
    html_content = fetch_html_from_github(gh_base_url, docs_path, cf_release_version)
  else
    halt 404, erb(template, locals: {
      header: version_links_html(cf_release_version, docs_path),
      content: "Not Found"
    })
  end

  modify_html(html_content, docs_path, cf_release_version)
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
  html_content.gsub!(
    /\bhref=\"/,
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
  links = (CFD_VERSIONS.keys + API_VERSIONS.keys).map do |version|
    link_for(version, current_version, current_path)
  end.join(" ")

  locals = {
    links: links,
    release_candidate_link: link_for('release-candidate', current_version, current_path),
    current_version: current_version,
    current_cc_api_version: get_cc_api_version(current_version, true)
  }

  erb header_template, locals: locals
end

def get_cc_api_version(version, bolded = false)
  if API_VERSIONS.has_key?(version)
    num    = API_VERSIONS[version]["CC_API_VERSION"]
    prefix = bolded ? "<strong>- CC API VERSION</strong>" : "- CC API VERSION"
    return "#{prefix} #{num}"
  elsif CFD_VERSIONS.has_key?(version)
    num    = CFD_VERSIONS[version]["CC_API_VERSION"]
    prefix = bolded ? "<strong>- CC API VERSION</strong>" : "- CC API VERSION"
    return "#{prefix} #{num}"
  end

  ""
end

def link_for(version, current_version, current_path)
  cc_api_version = get_cc_api_version(version)
  version == current_version ? "<li><a href='#'> <strong>#{version} #{cc_api_version}</strong> </a></li>" : "<li><a href=\"/#{version}#{current_path}\">#{version} #{cc_api_version}</a></li>"
end
