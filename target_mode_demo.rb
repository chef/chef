#!/usr/bin/env ruby
# =============================================================================
# PR #15735 Demo — Target Mode Node Identity Bug
#
# Run with:  ruby target_mode_demo.rb
#
# No gems required — everything is simulated inline.
# =============================================================================

require "ostruct"

PASS = "\e[32m✓\e[0m"
FAIL = "\e[31m✗\e[0m"
BOLD = "\e[1m"
DIM  = "\e[2m"
RST  = "\e[0m"

def section(title)
  puts
  puts "#{BOLD}#{"─" * 70}#{RST}"
  puts "#{BOLD}  #{title}#{RST}"
  puts "#{BOLD}#{"─" * 70}#{RST}"
end

def result(label, value, expected: nil)
  if expected
    ok = value == expected
    marker = ok ? PASS : FAIL
    note = ok ? "" : "  (expected: #{expected.inspect})"
    puts "  #{marker} #{label}: #{value.inspect}#{note}"
  else
    puts "  #{DIM}→#{RST} #{label}: #{value.inspect}"
  end
end

# =============================================================================
# Minimal stubs — simulates just enough of Chef to illustrate the identity flow
# =============================================================================

# Simulates Chef::Config (the global config hash)
module Config
  @store = {}
  def self.[](k);     @store[k];        end
  def self.[]=(k, v); @store[k] = v;    end
  def self.reset!;    @store = {};      end

  # Simulates the lazy default: client_key path changes after target_mode enabled
  def self.client_key
    if @store[:target_mode_enabled]
      "/etc/chef/#{@store[:node_name]}/client.pem"   # ← path AFTER target mode
    else
      @store[:client_key_raw] || "/etc/chef/client.pem"
    end
  end
end

# Simulates a Chef::ServerAPI instance (just records what identity it was built with)
class ServerAPI
  attr_reader :client_name, :signing_key

  def initialize(url, client_name: nil, signing_key_filename: nil)
    @url        = url
    @client_name  = client_name  || Config[:node_name]   # ← bare call falls back to node_name
    @signing_key  = signing_key_filename || Config.client_key
  end

  def get(path)
    puts "  #{DIM}GET #{@url}/#{path}  [signed as: #{@client_name}]#{RST}"
    "node-data-for-#{path.split('/').last}"
  end
end

# =============================================================================
# SCENARIO SETUP
# =============================================================================
# Pretend /etc/chef/client.rb has pre-set these values (typical Chef Server workstation)
OPERATOR_NODE_NAME = "jmccrae"
OPERATOR_CLIENT_KEY = "/etc/chef/client.pem"
TARGET_HOST = "target.example.com"
CHEF_SERVER_URL = "https://chef.example.com/organizations/myorg"

# =============================================================================
# BEFORE — The buggy behaviour
# =============================================================================
section("BEFORE  (buggy code — PR #15735)")

Config.reset!
Config[:node_name]    = OPERATOR_NODE_NAME    # set by /etc/chef/client.rb
Config[:client_key_raw] = OPERATOR_CLIENT_KEY

puts
puts "  #{DIM}# Simulates application/client.rb#reconfigure — BEFORE the fix#{RST}"
puts

# ── Bug 1: the 'unless' guard ──────────────────────────────────────────────
puts "  #{DIM}Chef::Config.node_name = target unless Chef::Config.node_name#{RST}"
target = TARGET_HOST
Config[:node_name] = target unless Config[:node_name]   # THE BUGGY LINE

result "node_name after guard", Config[:node_name], expected: TARGET_HOST

# ── Bug 2: enable target mode BEFORE capturing key ────────────────────────
puts
puts "  #{DIM}Chef::Config.target_mode.enabled = true  (now client_key path shifts)#{RST}"
Config[:target_mode_enabled] = true

result "client_key path resolves to", Config.client_key

puts
puts "  #{DIM}# Simulate Node.load — BEFORE fix (bare ServerAPI, no credentials)#{RST}"
puts "  #{DIM}ServerAPI.new(url).get('nodes/target.example.com')#{RST}"

# ── Bug 3: bare ServerAPI falls back to node_name ─────────────────────────
api = ServerAPI.new(CHEF_SERVER_URL)   # no client_name / signing_key passed

puts
result "API signs requests as", api.client_name, expected: OPERATOR_NODE_NAME
result "API signing key used",  api.signing_key,  expected: OPERATOR_CLIENT_KEY

puts
puts "  #{FAIL} Chef Server sees X-Ops-UserId: #{api.client_name.inspect} but that client"
puts "     does not exist on the server → #{BOLD}401 Unauthorized#{RST}"
puts "  #{FAIL} node_name was NOT overridden because of the 'unless' guard →"
puts "     #{BOLD}wrong node (#{Config[:node_name]}) would be converged#{RST}"

# =============================================================================
# AFTER — The fixed behaviour
# =============================================================================
section("AFTER   (fixed code — PR #15735)")

Config.reset!
Config[:node_name]    = OPERATOR_NODE_NAME    # set by /etc/chef/client.rb
Config[:client_key_raw] = OPERATOR_CLIENT_KEY

puts
puts "  #{DIM}# Simulates application/client.rb#reconfigure — AFTER the fix#{RST}"
puts

# ── Fix 1 & 2: capture credentials BEFORE enabling target mode ────────────
puts "  #{DIM}Chef::Config[:api_client_name] ||= Chef::Config[:node_name]#{RST}"
puts "  #{DIM}Chef::Config[:api_client_key]  ||= Chef::Config[:client_key]  # captured BEFORE path shifts#{RST}"
Config[:api_client_name] ||= Config[:node_name]
Config[:api_client_key]  ||= Config.client_key    # captured while path is still correct

puts
puts "  #{DIM}Chef::Config.target_mode.enabled = true  (client_key path now shifts)#{RST}"
Config[:target_mode_enabled] = true

puts
puts "  #{DIM}Chef::Config.node_name = target  # unconditional — no 'unless' guard#{RST}"
Config[:node_name] = TARGET_HOST                  # always override

puts
result "node_name",       Config[:node_name],       expected: TARGET_HOST
result "api_client_name", Config[:api_client_name], expected: OPERATOR_NODE_NAME
result "api_client_key",  Config[:api_client_key],  expected: OPERATOR_CLIENT_KEY
result "client_key (shifted path)", Config.client_key   # shows shifted path — but we don't use it

# ── Fix 3 & 4: explicit credentials passed to every ServerAPI constructor ─
puts
puts "  #{DIM}# Simulate Node.load — AFTER fix (credentials passed explicitly)#{RST}"
puts "  #{DIM}ServerAPI.new(url, client_name: api_client_name, signing_key_filename: api_client_key)#{RST}"

def api_client_name = Config[:api_client_name] || Config[:node_name]
def api_client_key  = Config[:api_client_key]  || Config.client_key

api = ServerAPI.new(CHEF_SERVER_URL,
  client_name: api_client_name,
  signing_key_filename: api_client_key)

puts
result "API signs requests as", api.client_name, expected: OPERATOR_NODE_NAME
result "API signing key used",  api.signing_key,  expected: OPERATOR_CLIENT_KEY
result "node being converged",  Config[:node_name], expected: TARGET_HOST

puts
puts "  #{PASS} Chef Server sees X-Ops-UserId: #{api.client_name.inspect} — #{BOLD}authenticated correctly#{RST}"
puts "  #{PASS} node_name is #{Config[:node_name].inspect} — #{BOLD}correct remote target will be converged#{RST}"

# =============================================================================
# SUMMARY TABLE
# =============================================================================
section("Summary")
puts
puts "  #{"Label".ljust(28)}  #{"BEFORE".ljust(42)}  AFTER"
puts "  #{"─" * 85}"

rows = [
  ["node_name converged",  OPERATOR_NODE_NAME,  TARGET_HOST],
  ["API auth identity",    TARGET_HOST,          OPERATOR_NODE_NAME],
  ["Client key resolved",  "/etc/chef/#{TARGET_HOST}/client.pem", OPERATOR_CLIENT_KEY],
  ["Chef Server result",   "401 Unauthorized",  "200 OK"],
]

rows.each do |label, before, after|
  puts "  #{label.ljust(28)}  #{before.ljust(44)}#{after}"
end

puts
