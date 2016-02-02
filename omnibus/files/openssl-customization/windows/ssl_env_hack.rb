#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
# that ships with omnibus packages of Chef and Chef DK. If this environment
# variable is already configured, this script is a no-op.
#
# This is required to make Chef tools use https URLs out of the box.

unless ENV.key?("SSL_CERT_FILE")
  base_dirs = File.dirname(__FILE__).split(File::SEPARATOR)

  (base_dirs.length - 1).downto(0) do |i|
    candidate_ca_bundle = File.join(base_dirs[0..i] + [ "ssl/certs/cacert.pem" ])
    if File.exist?(candidate_ca_bundle)
      ENV["SSL_CERT_FILE"] = candidate_ca_bundle
      break
    end
  end
end
