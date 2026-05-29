#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
require "chef/api_client/registration"

reg = Chef::ApiClient::Registration.new("bench-client", "/tmp/bench-client.pem")

response_plain = { "public_key" => "plain-public-key", "private_key" => "plain-private-key" }
key_obj = Object.new
def key_obj.to_pem
  "pem-public-key"
end
response_obj = { "public_key" => key_obj }
response_nested = { "chef_key" => { "public_key" => "nested-public-key", "private_key" => "nested-private-key" } }

n = Integer(ENV.fetch("API_CLIENT_KEY_ITERATIONS", "200000"))
plain_t = Benchmark.realtime { n.times { reg.api_client_key(response_plain, "public_key") } }
obj_t = Benchmark.realtime { n.times { reg.api_client_key(response_obj, "public_key") } }
nested_t = Benchmark.realtime { n.times { reg.api_client_key(response_nested, "private_key") } }

n2 = Integer(ENV.fetch("KEY_MATERIAL_ITERATIONS", "20000"))
pub_t = Benchmark.realtime { n2.times { reg.generated_public_key } }
priv_t = Benchmark.realtime { n2.times { reg.private_key } }

puts "METRIC api_client_key_plain_s=#{format("%.6f", plain_t)}"
puts "METRIC api_client_key_object_s=#{format("%.6f", obj_t)}"
puts "METRIC api_client_key_nested_s=#{format("%.6f", nested_t)}"
puts "METRIC generated_public_key_s=#{format("%.6f", pub_t)}"
puts "METRIC private_key_s=#{format("%.6f", priv_t)}"
