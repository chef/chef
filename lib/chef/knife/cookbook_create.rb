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

class Chef
  class Knife
    class CookbookCreate < Knife

      deps do
        require 'chef/json_compat'
        require 'uri'
        require 'fileutils'
      end

      banner "knife cookbook create COOKBOOK (options)"

      option :cookbook_path,
        :short => "-o PATH",
        :long => "--cookbook-path PATH",
        :description => "The directory where the cookbook will be created"

      option :readme_format,
        :short => "-r FORMAT",
        :long => "--readme-format FORMAT",
        :description => "Format of the README file, supported formats are 'md' (markdown) and 'rdoc' (rdoc)"

      option :cookbook_license,
        :short => "-I LICENSE",
        :long => "--license LICENSE",
        :description => "License for cookbook, apachev2, gplv2, gplv3, mit or none"

      option :cookbook_copyright,
        :short => "-C COPYRIGHT",
        :long => "--copyright COPYRIGHT",
        :description => "Name of Copyright holder"

      option :cookbook_email,
        :short => "-m EMAIL",
        :long => "--email EMAIL",
        :description => "Email address of cookbook maintainer"

      def run
        self.config = Chef::Config.merge!(config)
        if @name_args.length < 1
          show_usage
          ui.fatal("You must specify a cookbook name")
          exit 1
        end

        if default_cookbook_path_empty? && parameter_empty?(config[:cookbook_path])
          raise ArgumentError, "Default cookbook_path is not specified in the knife.rb config file, and a value to -o is not provided. Nowhere to write the new cookbook to."
        end

        cookbook_path = File.expand_path(Array(config[:cookbook_path]).first)
        cookbook_name = @name_args.first
        copyright = config[:cookbook_copyright] || "YOUR_COMPANY_NAME"
        email = config[:cookbook_email] || "YOUR_EMAIL"
        license = ((config[:cookbook_license] != "false") && config[:cookbook_license]) || "none"
        readme_format = ((config[:readme_format] != "false") && config[:readme_format]) || "md"
        create_cookbook(cookbook_path, cookbook_name, copyright, license)
        create_readme(cookbook_path, cookbook_name, readme_format)
        create_changelog(cookbook_path, cookbook_name)
        create_metadata(cookbook_path, cookbook_name, copyright, email, license, readme_format)
      end

      def create_cookbook(dir, cookbook_name, copyright, license)
        msg("** Creating cookbook #{cookbook_name}")
        FileUtils.mkdir_p "#{File.join(dir, cookbook_name, "attributes")}"
        FileUtils.mkdir_p "#{File.join(dir, cookbook_name, "recipes")}"
        FileUtils.mkdir_p "#{File.join(dir, cookbook_name, "definitions")}"
        FileUtils.mkdir_p "#{File.join(dir, cookbook_name, "libraries")}"
        FileUtils.mkdir_p "#{File.join(dir, cookbook_name, "resources")}"
        FileUtils.mkdir_p "#{File.join(dir, cookbook_name, "providers")}"
        FileUtils.mkdir_p "#{File.join(dir, cookbook_name, "files", "default")}"
        FileUtils.mkdir_p "#{File.join(dir, cookbook_name, "templates", "default")}"
        unless File.exists?(File.join(dir, cookbook_name, "recipes", "default.rb"))
          open(File.join(dir, cookbook_name, "recipes", "default.rb"), "w") do |file|
            file.puts <<-EOH
#
# Cookbook Name:: #{cookbook_name}
# Recipe:: default
#
# Copyright #{Time.now.year}, #{copyright}
#
EOH
            case license
            when "apachev2"
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
            when "gplv2"
              file.puts <<-EOH
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
EOH
            when "gplv3"
              file.puts <<-EOH
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
EOH
            when "mit"
              file.puts <<-EOH
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
EOH
            when "none"
              file.puts <<-EOH
# All rights reserved - Do Not Redistribute
#
EOH
            end
          end
        end
      end

      def create_changelog(dir, cookbook_name)
        msg("** Creating CHANGELOG for cookbook: #{cookbook_name}")
        unless File.exists?(File.join(dir,cookbook_name,'CHANGELOG.md'))
          open(File.join(dir, cookbook_name, 'CHANGELOG.md'),'w') do |file|
            file.puts <<-EOH
# CHANGELOG for #{cookbook_name}

This file is used to list changes made in each version of #{cookbook_name}.

## 0.1.0:

* Initial release of #{cookbook_name}

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
EOH
          end
        end
      end

      def create_readme(dir, cookbook_name, readme_format)
        msg("** Creating README for cookbook: #{cookbook_name}")
        unless File.exists?(File.join(dir, cookbook_name, "README.#{readme_format}"))
          open(File.join(dir, cookbook_name, "README.#{readme_format}"), "w") do |file|
            case readme_format
            when "rdoc"
              file.puts <<-EOH
= #{cookbook_name} Cookbook
TODO: Enter the cookbook description here.

e.g.
This cookbook makes your favorite breakfast sandwhich.

== Requirements
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

e.g.
==== packages
- +toaster+ - #{cookbook_name} needs toaster to brown your bagel.

== Attributes
TODO: List you cookbook attributes here.

e.g.
==== #{cookbook_name}::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['#{cookbook_name}']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

== Usage
==== #{cookbook_name}::default
TODO: Write usage instructions for each cookbook.

e.g.
Just include +#{cookbook_name}+ in your node's +run_list+:

    {
      "name":"my_node",
      "run_list": [
        "recipe[#{cookbook_name}]"
      ]
    }

== Contributing
TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

== License and Authors
Authors: TODO: List authors
EOH
            when "md","mkd","txt"
              file.puts <<-EOH
#{cookbook_name} Cookbook
#{'='*"#{cookbook_name} Cookbook".length}
TODO: Enter the cookbook description here.

e.g.
This cookbook makes your favorite breakfast sandwhich.

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

e.g.
#### packages
- `toaster` - #{cookbook_name} needs toaster to brown your bagel.

Attributes
----------
TODO: List you cookbook attributes here.

e.g.
#### #{cookbook_name}::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['#{cookbook_name}']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----
#### #{cookbook_name}::default
TODO: Write usage instructions for each cookbook.

e.g.
Just include `#{cookbook_name}` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[#{cookbook_name}]"
  ]
}
```

Contributing
------------
TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: TODO: List authors
EOH
            else
              file.puts <<-EOH
#{cookbook_name} Cookbook
#{'='*"#{cookbook_name} Cookbook".length}
  TODO: Enter the cookbook description here.

  e.g.
  This cookbook makes your favorite breakfast sandwhich.

Requirements
  TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

  e.g.
  toaster         #{cookbook_name} needs toaster to brown your bagel.

Attributes
  TODO: List you cookbook attributes here.

  #{cookbook_name}
  Key                                   Type        Description                           Default
  ['#{cookbook_name}']['bacon']         Boolean     whether to include bacon              true

Usage
  #{cookbook_name}
  TODO: Write usage instructions for each cookbook.

  e.g.
  Just include `#{cookbook_name}` in your node's `run_list`:

  [code]
  {
    "name":"my_node",
    "run_list": [
      "recipe[#{cookbook_name}]"
    ]
  }
  [/code]

Contributing
  TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

  e.g.
  1. Fork the repository on Github
  2. Create a named feature branch (like `add_component_x`)
  3. Write you change
  4. Write tests for your change (if applicable)
  5. Run the tests, ensuring they all pass
  6. Submit a Pull Request using Github

License and Authors
  Authors: TODO: List authors
EOH
            end
          end
        end
      end

      def create_metadata(dir, cookbook_name, copyright, email, license, readme_format)
        msg("** Creating metadata for cookbook: #{cookbook_name}")

        license_name = case license
                       when "apachev2"
                         "Apache 2.0"
                       when "gplv2"
                         "GNU Public License 2.0"
                       when "gplv3"
                         "GNU Public License 3.0"
                       when "mit"
                         "MIT"
                       when "none"
                         "All rights reserved"
                       end

        unless File.exists?(File.join(dir, cookbook_name, "metadata.rb"))
          open(File.join(dir, cookbook_name, "metadata.rb"), "w") do |file|
            if File.exists?(File.join(dir, cookbook_name, "README.#{readme_format}"))
              long_description = "long_description IO.read(File.join(File.dirname(__FILE__), 'README.#{readme_format}'))"
            end
            file.puts <<-EOH
name             '#{cookbook_name}'
maintainer       '#{copyright}'
maintainer_email '#{email}'
license          '#{license_name}'
description      'Installs/Configures #{cookbook_name}'
#{long_description}
version          '0.1.0'
EOH
          end
        end
      end

      private

      def default_cookbook_path_empty?
        Chef::Config[:cookbook_path].nil? || Chef::Config[:cookbook_path].empty?
      end

      def parameter_empty?(parameter)
        parameter.nil? || parameter.empty?
      end

    end
  end
end
