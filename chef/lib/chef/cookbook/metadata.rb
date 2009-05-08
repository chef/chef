#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'chef/mixin/params_validate'
require 'chef/mixin/check_helper'
require 'chef/log'

#{ 
#  cookbook: "test",
#  maintainer: "something",
#  maintainer_email: "someone@example.com",
#  license: 'Apache v2',
#  description: 'Short description of the cookbook'
#  platforms: {
#    'ubuntu': [ ">= 9.04", "= 8.04" ]
#  }
#}
#
#   maintainer "Adam Jacob"
#   maintainer_email "adam@opscode.com"
#   license 'Apache v2.0'
#   description 'A fabulous new cookbook'
#   version 1.0
#
#   supports :ubuntu, ">= 8.04"
#   supports :redhat, ">= 5"
#
#   provides :all, "meta_recipe"
#   suggests :all, "apache_bench"
#
#   depends "build_essential", ">> 0.8"
#
#   conflicts :all, "nginx"
#   conflicts :all, "lighttpd"
#
#   supersedes "apache2"
#

class Chef
  class Cookbook
    class Metadata
    
      include Chef::Mixin::CheckHelper
      include Chef::Mixin::ParamsValidate

      attr_reader :cookbook, :platforms, :dependencies, :recommendations, :suggestions, :conflicting, :providing, :replacing, :attributes

      def initialize(cookbook, maintainer='Your Name', maintainer_email='youremail@example.com', license='Apache v2.0')
        raise ArgumentError unless cookbook.kind_of?(Chef::Cookbook)
        @cookbook = cookbook
        self.maintainer(maintainer)
        self.maintainer_email(maintainer_email)
        self.license(license)
        self.description('A fabulous new cookbook')
        @platforms = Mash.new
        @dependencies = Mash.new
        @recommendations = Mash.new
        @suggestions = Mash.new
        @conflicting = Mash.new
        @providing = Mash.new
        @replacing = Mash.new
        @attributes = Mash.new
      end

      def maintainer(arg=nil)
        set_or_return(
          :maintainer,
          arg,
          :kind_of => [ String ]
        )
      end

      def maintainer_email(arg=nil)
        set_or_return(
          :maintainer_email,
          arg,
          :kind_of => [ String ]
        )
      end

      def license(arg=nil)
        set_or_return(
          :license,
          arg,
          :kind_of => [ String ]
        )
      end

      def description(arg=nil)
        set_or_return(
          :description,
          arg,
          :kind_of => [ String ]
        )
      end

      def long_description(arg=nil)
        set_or_return(
          :description,
          arg,
          :kind_of => [ String ]
        )
      end

      def version(arg=nil)
        set_or_return(
          :version,
          arg,
          :regex => /^\d+\.\d+$/
        )
      end

      def name
        @cookbook.name
      end

      def supports(platform, *versions)
        versions.each { |v| _check_version_expression(v) }
        @platforms[platform] = versions
        @platforms[platform]
      end

      def depends(cookbook, *versions)
        @dependencies[cookbook] = versions
        @dependencies[cookbook]
      end

      def recommends(cookbook, *versions)
        @recommendations[cookbook] = versions
        @recommendations[cookbook]
      end

      def suggests(cookbook, *versions)
        @suggestions[cookbook] = versions
        @suggestions[cookbook] 
      end

      def conflicts(cookbook, *versions)
        @conflicting[cookbook] = versions
        @conflicting[cookbook] 
      end

      def provides(cookbook, *versions)
        @providing[cookbook] = versions
        @providing[cookbook] 
      end

      def replaces(cookbook, *versions)
        @replacing[cookbook] = versions
        @replacing[cookbook] 
      end

      def attribute(name, options)
        validate(
          options,
          {
            :display_name => { :kind_of => String },
            :description => { :kind_of => String },
            :multiple_values => { :equal_to => [ true, false ], :default => false },
            :type => { :equal_to => [ "string", "array", "hash" ], :default => "string" },
            :required => { :equal_to => [ true, false ], :default => false },
            :recipes => { :kind_of => [ Array ], :default => [] },
            :default => { :kind_of => [ String, Array, Hash ] }
          }
        )
        @attributes[name] = options 
        @attributes[name]
      end

      def _check_version_expression(version_string)
        if version_string =~ /^(>>|>=|=|<=|<<) (.+)$/
          [ $1, $2 ]
        else
          raise ArgumentError, "Version expression #{version_string} is invalid!"
        end
      end

      def _check_valid_version(to_check, version_string)
        (selector, version) = _check_version_expression(version_string) 
        case selector
        when "<<"
          to_check < version
        when "<="
          to_check <= version
        when "="
          to_check == version
        when ">="
          to_check >= version
        when ">>"
          to_check > version
        end
      end
    end
  end
end
