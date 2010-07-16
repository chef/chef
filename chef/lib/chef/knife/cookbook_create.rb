#
# Author:: Nuo Yan (<nuo@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/knife'
require 'json'
require 'uri'
require 'chef/mixin/shell_out'

class Chef
  class Knife
    class CookbookCreate < Knife
      include Chef::Mixin::ShellOut

      banner "knife cookbook new COOKBOOK [COMPANY_NAME_FOR_COPYRIGHT] [EMAIL] [APACHE_LICENSE=false] (options)"

      option :cookbook_path,
        :short => "-o PATH",
        :long => "--cookbook-path PATH",
        :description => "The directory where the cookbook will be created"

      def run
         if @name_args.length < 1
            show_usage
            Chef::Log.fatal("You must specify a cookbook name")
            exit 1
        end

        if default_cookbook_path_empty? && given_cookbook_path_empty?
          raise ArgumentError, "Default cookbook_path is not specified in the knife.rb config file, and a value to -o is not provided. Nowhere to write the new cookbook to."
        end

        cookbook_path = given_cookbook_path_empty? ? Chef::Config[:cookbook_path].first : config[:cookbook_path]
        cookbook_name = @name_args.first
        company_name = @name_args[1].nil? || @name_args[1].empty? ? "YOUR_COMPANY_NAME" : @name_args[1]
        email = @name_args[2].nil? || @name_args[2].empty? ? "YOUR_EMAIL" : @name_args[2]
        license = (@name_args[3].nil? || @name_args[3].to_s.empty? || @name_args[3] == false || @name_args[3] == 'false') ? :none : :apachev2
        create_cookbook(cookbook_path,cookbook_name, company_name, license)
        create_readme(cookbook_path,cookbook_name)
        create_metadata(cookbook_path,cookbook_name, company_name, email, license)
    end

    def create_cookbook(dir, cookbook_name, company_name, license)
      msg("** Creating cookbook #{cookbook_name}")
      shell_out "mkdir -p #{File.join(dir, cookbook_name, "attributes")}"
      shell_out "mkdir -p #{File.join(dir, cookbook_name, "recipes")}"
      shell_out "mkdir -p #{File.join(dir, cookbook_name, "definitions")}"
      shell_out "mkdir -p #{File.join(dir, cookbook_name, "libraries")}"
      shell_out "mkdir -p #{File.join(dir, cookbook_name, "resources")}"
      shell_out "mkdir -p #{File.join(dir, cookbook_name, "providers")}"
      shell_out "mkdir -p #{File.join(dir, cookbook_name, "files", "default")}"
      shell_out "mkdir -p #{File.join(dir, cookbook_name, "templates", "default")}"
      unless File.exists?(File.join(dir, cookbook_name, "recipes", "default.rb"))
        open(File.join(dir, cookbook_name, "recipes", "default.rb"), "w") do |file|
          file.puts <<-EOH
#
# Cookbook Name:: #{cookbook_name}
# Recipe:: default
#
# Copyright #{Time.now.year}, #{company_name}
#
EOH
          case license
          when :apachev2
            file.puts <<-EOH
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
EOH
          when :none
            file.puts <<-EOH
# All rights reserved - Do Not Redistribute
#
EOH
          end
        end
      end
    end

    def create_readme(dir, cookbook_name)
      msg("** Creating README for cookbook: #{cookbook_name}")
      unless File.exists?(File.join(dir, cookbook_name, "README.rdoc"))
        open(File.join(dir, cookbook_name, "README.rdoc"), "w") do |file|
          file.puts <<-EOH
= DESCRIPTION:

= REQUIREMENTS:

= ATTRIBUTES:

= USAGE:

EOH
        end
      end
    end

    def create_metadata(dir, cookbook_name, company_name, email, license)
      msg("** Creating metadata for cookbook: #{cookbook_name}")

      license_name = case license
                     when :apachev2
                       "Apache 2.0"
                     when :none
                       "All rights reserved"
                     end

      unless File.exists?(File.join(dir, cookbook_name, "metadata.rb"))
        open(File.join(dir, cookbook_name, "metadata.rb"), "w") do |file|
          if File.exists?(File.join(dir, cookbook_name, 'README.rdoc'))
            long_description = "long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))"
          end
          file.puts <<-EOH
maintainer       "#{company_name}"
maintainer_email "#{email}"
license          "#{license_name}"
description      "Installs/Configures #{cookbook_name}"
#{long_description}
version          "0.0.1"
EOH
        end
      end
    end

    private
    def default_cookbook_path_empty?
      Chef::Config[:cookbook_path].nil? || Chef::Config[:cookbook_path].empty?
    end

    def given_cookbook_path_empty?
      config[:cookbook_path].nil? || config[:cookbook_path].empty?
    end

    end
  end
end