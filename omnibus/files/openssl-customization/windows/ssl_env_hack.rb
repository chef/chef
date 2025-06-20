#
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script sets the SSL_CERT_FILE environment variable to the CA cert bundle
# that ships with omnibus packages of Chef Infra Client and Chef Workstation. If
# this environment variable is already configured, this script is a no-op.
#
# This is required to make Chef tools use https URLs out of the box.

puts "<<< included the ssl_env_hack.rb script >>>"
SSL_ENV_CACERT_PATCH = true unless defined?(SSL_ENV_CACERT_PATCH)

unless ENV.key?("SSL_CERT_FILE")
  base_dirs = __dir__.split(File::SEPARATOR)

  (base_dirs.length - 1).downto(0) do |i|
    candidate_ca_bundle = Dir["c:/hab/pkgs/core/openssl/*/ssl/certs/cacert.pem"].first
    puts "Checking for CA bundle at: #{candidate_ca_bundle}"
    if candidate_ca_bundle && File.exist?(candidate_ca_bundle)
      ENV["SSL_CERT_FILE"] = candidate_ca_bundle
      break
    end
  end
end
