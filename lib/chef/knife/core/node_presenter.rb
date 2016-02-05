#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

require "chef/knife/core/text_formatter"
require "chef/knife/core/generic_presenter"

class Chef
  class Knife
    module Core

      # This module may be included into a knife subcommand class to automatically
      # add configuration options used by the NodePresenter
      module NodeFormattingOptions
        # :nodoc:
        # Would prefer to do this in a rational way, but can't be done b/c of
        # Mixlib::CLI's design :(
        def self.included(includer)
          includer.class_eval do
            option :medium_output,
              :short   => "-m",
              :long    => "--medium",
              :boolean => true,
              :default => false,
              :description => "Include normal attributes in the output"

            option :long_output,
              :short   => "-l",
              :long    => "--long",
              :boolean => true,
              :default => false,
              :description => "Include all attributes in the output"
          end
        end
      end

      #==Chef::Knife::Core::NodePresenter
      # A customized presenter for Chef::Node objects. Supports variable-length
      # output formats for displaying node data
      class NodePresenter < GenericPresenter

        def format(data)
          if parse_format_option == :json
            summarize_json(data)
          else
            super
          end
        end

        def summarize_json(data)
          if data.kind_of?(Chef::Node)
            node = data
            result = {}

            result["name"] = node.name
            if node.policy_name.nil? && node.policy_group.nil?
              result["chef_environment"] = node.chef_environment
            else
              result["policy_name"] = node.policy_name
              result["policy_group"] = node.policy_group
            end
            result["run_list"] = node.run_list
            result["normal"] = node.normal_attrs

            if config[:long_output]
              result["default"]   = node.default_attrs
              result["override"]  = node.override_attrs
              result["automatic"] = node.automatic_attrs
            end

            Chef::JSONCompat.to_json_pretty(result)
          else
            Chef::JSONCompat.to_json_pretty(data)
          end
        end

        # Converts a Chef::Node object to a string suitable for output to a
        # terminal. If config[:medium_output] or config[:long_output] are set
        # the volume of output is adjusted accordingly. Uses colors if enabled
        # in the ui object.
        def summarize(data)
          if data.kind_of?(Chef::Node)
            node = data
            # special case ec2 with their split horizon whatsis.
            ip = (node[:ec2] && node[:ec2][:public_ipv4]) || node[:ipaddress]

            summarized = <<-SUMMARY
#{ui.color('Node Name:', :bold)}   #{ui.color(node.name, :bold)}
SUMMARY
            show_policy = !(node.policy_name.nil? && node.policy_group.nil?)
            if show_policy
              summarized << <<-POLICY
#{key('Policy Name:')}  #{node.policy_name}
#{key('Policy Group:')} #{node.policy_group}
POLICY
            else
              summarized << <<-ENV
#{key('Environment:')} #{node.chef_environment}
ENV
            end
            summarized << <<-SUMMARY
#{key('FQDN:')}        #{node[:fqdn]}
#{key('IP:')}          #{ip}
#{key('Run List:')}    #{node.run_list}
SUMMARY
            unless show_policy
              summarized << <<-ROLES
#{key('Roles:')}       #{Array(node[:roles]).join(', ')}
ROLES
            end
            summarized << <<-SUMMARY
#{key('Recipes:')}     #{Array(node[:recipes]).join(', ')}
#{key('Platform:')}    #{node[:platform]} #{node[:platform_version]}
#{key('Tags:')}        #{node.tags.join(', ')}
SUMMARY
            if config[:medium_output] || config[:long_output]
              summarized += <<-MORE
#{key('Attributes:')}
#{text_format(node.normal_attrs)}
MORE
            end
            if config[:long_output]
              summarized += <<-MOST
#{key('Default Attributes:')}
#{text_format(node.default_attrs)}
#{key('Override Attributes:')}
#{text_format(node.override_attrs)}
#{key('Automatic Attributes (Ohai Data):')}
#{text_format(node.automatic_attrs)}
MOST
            end
            summarized
          else
            super
          end
        end

        def key(key_text)
          ui.color(key_text, :cyan)
        end

      end
    end
  end
end
