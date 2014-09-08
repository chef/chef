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

name "openssl-customization"

default_version "0.1.0"

if platform == 'windows'
  dependency "ruby-windows"
else
  dependency "ruby"
  dependency "rubygems"
end

build do
  if platform == "windows"
    block do
      # gets directories for RbConfig::CONFIG and sanitizes them.
      def get_sanitized_rbconfig(config)
        config_cmd = %Q{#{install_dir}/embedded/bin/ruby -rrbconfig -e "puts RbConfig::CONFIG['#{config}']"}
        config_cmd.gsub!('/', '\\') if platform == "windows"

        config_dir = ""
        Bundler.with_clean_env do
          config_dir = %x{#{config_cmd}}.strip
        end

        raise "could not determine embedded ruby's RbConfig::CONFIG['#{config}']" if config_dir.empty?

        if sysdrive = ENV['SYSTEMDRIVE']
          match_drive = Regexp.new(Regexp.escape(sysdrive), Regexp::IGNORECASE)
          config_dir.sub!(match_drive, '')
        end

        config_dir
      end

      def embedded_ruby_site_dir
        get_sanitized_rbconfig('sitelibdir')
      end

      def embedded_ruby_lib_dir
        get_sanitized_rbconfig('rubylibdir')
      end

      destination_ssl_env_hack = File.join(embedded_ruby_site_dir, "ssl_env_hack.rb")
      source_ssl_env_hack = File.join(project.files_path, "openssl_customization", "windows", "ssl_env_hack.rb")
      FileUtils.cp source_ssl_env_hack, destination_ssl_env_hack

      # Unfortunately there is no patch on windows, but luckily we only need to append a line to the openssl.rb
      # to pick up our script which find the CA bundle in omnibus installations and points SSL_CERT_FILE to it
      # if it's not already set
      source_openssl_rb = File.join(embedded_ruby_lib_dir, "openssl.rb")
      original_openssl_rb = File.read(source_openssl_rb)
      File.open(source_openssl_rb, "w") do |f|
        f.write(original_openssl_rb + "\nrequire 'ssl_env_hack'\n")
      end
    end
  end
end
