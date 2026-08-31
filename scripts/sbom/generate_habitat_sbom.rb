#!/usr/bin/env ruby
# Parses Habitat plan files and generates a CycloneDX 1.4 SBOM for direct
# upload to BlackDuck via the /api/scan/data endpoint.
# Output: habitat-components.cdx.json (repo root by default)

require "json"
require "net/http"
require "uri"
require "time"

BLDR_API      = "https://bldr.habitat.sh/v1/depot/pkgs".freeze
HAB_CHANNEL   = "base-2025".freeze
REPO_ROOT     = File.expand_path("../..", __dir__)
# Packages excluded from the SBOM (e.g. macOS SDK, not a shippable open-source dep)
OMIT_PACKAGES = %w[xcode].freeze

PLAN_FILES = {
  "x86_64-linux"   => File.join(REPO_ROOT, "habitat/x86_64-linux/plan.sh"),
  "aarch64-linux"  => File.join(REPO_ROOT, "habitat/aarch64-linux/plan.sh"),
  "aarch64-darwin" => File.join(REPO_ROOT, "habitat/aarch64-darwin/plan.sh"),
  "x86_64-windows" => File.join(REPO_ROOT, "habitat/x86_64-windows/plan.ps1"),
}.freeze

# --------------------------------------------------------------------------- #
# Parsing                                                                      #
# --------------------------------------------------------------------------- #

# Returns { runtime: [...], build: [...] } where each entry is
# { origin:, name:, pinned_version: (or nil) }
def parse_bash_plan(path)
  text = File.read(path)

  # Capture shell variable assignments so we can expand references like
  # $_chef_client_ruby in array bodies.
  vars = {}
  text.scan(/^(\w+)="([^"]*)"/) { vars[$1] = $2 }

  extract = lambda do |array_name|
    # Match the array body: pkg_deps=( ... )
    m = text.match(/^#{Regexp.escape(array_name)}\s*=\s*\(\s*(.*?)\s*\)/m)
    return [] unless m

    body = m[1]
    # Expand known shell variable references
    body = body.gsub(/\$\{?(\w+)\}?/) { vars[$1] || "" }
    # Each token is an unquoted word (comments stripped)
    body.split(/[\s\n]+/).grep_v(/^#/).reject(&:empty?).map do |token|
      parts = token.split("/")
      { origin: parts[0], name: parts[1], pinned_version: parts[2] }
    end
  end

  {
    runtime: extract.call("pkg_deps"),
    build:   extract.call("pkg_build_deps"),
  }
end

def parse_ps1_plan(path)
  text = File.read(path)

  extract = lambda do |array_name|
    # Match: $pkg_deps=@( ... )
    m = text.match(/^\$#{Regexp.escape(array_name)}\s*=\s*@\(\s*(.*?)\s*\)/m)
    return [] unless m

    m[1].scan(/"([^"]+)"/).flatten.map do |token|
      parts = token.split("/")
      { origin: parts[0], name: parts[1], pinned_version: parts[2] }
    end
  end

  {
    runtime: extract.call("pkg_deps"),
    build:   extract.call("pkg_build_deps"),
  }
end

def parse_plan(platform, path)
  if path.end_with?(".ps1")
    parse_ps1_plan(path)
  else
    parse_bash_plan(path)
  end
end

# --------------------------------------------------------------------------- #
# Habitat Builder API                                                          #
# --------------------------------------------------------------------------- #

@pkg_cache = {}

# Returns { version: String, tdeps: [{origin:, name:, version:}] }
# tdeps is filtered to core-origin only — the only packages with BD KB entries.
# target must be passed so the API returns platform-specific dep trees.
def fetch_pkg_metadata(origin, name, pinned_version, target)
  key = "#{origin}/#{name}/#{pinned_version}/#{target}"
  return @pkg_cache[key] if @pkg_cache.key?(key)

  url = if pinned_version
    "#{BLDR_API}/#{origin}/#{name}/#{pinned_version}/latest?channel=#{HAB_CHANNEL}&target=#{target}"
  else
    "#{BLDR_API}/#{origin}/#{name}/latest?channel=#{HAB_CHANNEL}&target=#{target}"
  end

  uri = URI.parse(url)
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{ENV["HAB_AUTH_TOKEN"]}" if ENV["HAB_AUTH_TOKEN"]

  resp = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |h| h.request(req) }

  result = if resp.is_a?(Net::HTTPSuccess)
    data    = JSON.parse(resp.body)
    version = data.dig("ident", "version") || pinned_version || "unknown"
    tdeps   = (data["tdeps"] || [])
      .select { |d| d["origin"] == "core" }
      .map    { |d| { origin: d["origin"], name: d["name"], version: d["version"] } }
    { version: version, tdeps: tdeps }
  else
    warn "  WARNING: #{resp.code} for #{origin}/#{name} — using pinned or 'unknown'"
    { version: pinned_version || "unknown", tdeps: [] }
  end

  @pkg_cache[key] = result
end

# --------------------------------------------------------------------------- #
# CycloneDX generation                                                         #
# --------------------------------------------------------------------------- #

def purl(name, version)
  "pkg:generic/#{name}@#{version}"
end

def component_json(origin, name, version, scope)
  {
    "type"    => "library",
    "group"   => origin,
    "name"    => "Habitat core_#{name}",
    "version" => version,
    "purl"    => purl(name, version),
    "properties" => [
      { "name" => "habitat:origin",  "value" => origin },
      { "name" => "habitat:channel", "value" => HAB_CHANNEL },
      { "name" => "habitat:scope",   "value" => scope },
    ],
  }
end

# Builds the component list for a single platform.
# Deduplicates within the platform; prefers runtime scope over build.
def build_platform_components(entries, target)
  seen       = {}
  components = []
  transitive = {}

  entries.each do |entry|
    next if OMIT_PACKAGES.include?(entry[:name])
    key = "#{entry[:origin]}/#{entry[:name]}"
    next if seen[key] && seen[key][:scope] == "runtime"
    seen[key] = entry
  end

  seen.each_value do |entry|
    meta    = fetch_pkg_metadata(entry[:origin], entry[:name], entry[:pinned_version], target)
    version = meta[:version]

    components << component_json(entry[:origin], entry[:name], version, entry[:scope])

    meta[:tdeps].each do |tdep|
      tdep_key = "#{tdep[:origin]}/#{tdep[:name]}"
      next if seen.key?(tdep_key) || OMIT_PACKAGES.include?(tdep[:name])
      transitive[tdep_key] ||= tdep
    end
  end

  transitive.each_value do |tdep|
    components << component_json(tdep[:origin], tdep[:name], tdep[:version], "transitive")
  end

  components
end

# --------------------------------------------------------------------------- #
# Main — one CycloneDX file per platform; merged by cyclonedx-cli in CI       #
# --------------------------------------------------------------------------- #

app_version = File.read(File.join(REPO_ROOT, "VERSION")).strip

PLAN_FILES.each do |platform, path|
  unless File.exist?(path)
    warn "SKIP: #{path} not found"
    next
  end

  puts "\nParsing #{platform}: #{path}"
  deps = parse_plan(platform, path)

  entries = []
  deps[:runtime].each { |pkg| entries << pkg.merge(scope: "runtime") }
  deps[:build].each   { |pkg| entries << pkg.merge(scope: "build") }

  puts "Resolving versions and transitive deps (channel: #{HAB_CHANNEL}, target: #{platform})..."
  components = build_platform_components(entries, platform)

  bom = {
    "bomFormat"   => "CycloneDX",
    "specVersion" => "1.4",
    "version"     => 1,
    "metadata"    => {
      "timestamp" => Time.now.utc.iso8601,
      "tools"     => [{ "name" => "scripts/sbom/generate_habitat_sbom.rb", "version" => "1.0" }],
      "component" => {
        "type"       => "application",
        "name"       => "chef-infra-client",
        "version"    => app_version,
        "properties" => [{ "name" => "habitat:platform", "value" => platform }],
      },
    },
    "components" => components,
  }

  output = File.join(REPO_ROOT, "habitat-components-#{platform}.cdx.json")
  File.write(output, JSON.pretty_generate(bom))
  puts "Written #{components.size} components to #{File.basename(output)}"
end
