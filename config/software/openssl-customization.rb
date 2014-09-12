#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

# This software makes sure that SSL_CERT_FILE environment variable is pointed
# to the bundled CA certificates that ship with omnibus. With this, Chef
# tools can be used with https URLs out of the box.
name "openssl-customization"

default_version "0.1.0"

source path: "#{project.files_path}/#{name}"

if windows?
  dependency "ruby-windows"
else
  dependency "ruby"
  dependency "rubygems"
end

build do
  if windows?
    block "Add OpenSSL customization file" do
      # gets directories for RbConfig::CONFIG and sanitizes them.
      def get_sanitized_rbconfig(config)
        ruby = windows_safe_path("#{install_dir}/embedded/bin/ruby")

        config_dir = Bundler.with_clean_env do
          command_output = %x|#{ruby} -rrbconfig -e "puts RbConfig::CONFIG['#{config}']"|.strip
          windows_safe_path(command_output)
        end

        if config_dir.nil? || config_dir.empty?
          raise "could not determine embedded ruby's RbConfig::CONFIG['#{config}']"
        end

        config_dir
      end

      embedded_ruby_site_dir = get_sanitized_rbconfig('sitelibdir')
      embedded_ruby_lib_dir  = get_sanitized_rbconfig('rubylibdir')

      source_ssl_env_hack      = File.join(project_dir, "windows", "ssl_env_hack.rb")
      destination_ssl_env_hack = File.join(embedded_ruby_site_dir, "ssl_env_hack.rb")

      copy(source_ssl_env_hack, destination_ssl_env_hack)

      # Unfortunately there is no patch on windows, but luckily we only need to append a line to the openssl.rb
      # to pick up our script which find the CA bundle in omnibus installations and points SSL_CERT_FILE to it
      # if it's not already set
      source_openssl_rb = File.join(embedded_ruby_lib_dir, "openssl.rb")
      File.open(source_openssl_rb, "a") do |f|
        f.write("\nrequire 'ssl_env_hack'\n")
      end
    end
  end
end
