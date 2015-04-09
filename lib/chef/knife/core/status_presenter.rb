#
# Author:: Nicolas DUPEUX (<nicolas.dupeux@arkea.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/knife/core/text_formatter'
require 'chef/knife/core/generic_presenter'

class Chef
  class Knife
    module Core

      # This module may be included into a knife subcommand class to automatically
      # add configuration options used by the StatusPresenter
      module StatusFormattingOptions
        # :nodoc:
        # Would prefer to do this in a rational way, but can't be done b/c of
        # Mixlib::CLI's design :(
        def self.included(includer)
          includer.class_eval do
            option :medium_output,
              :short   => '-m',
              :long    => '--medium',
              :boolean => true,
              :default => false,
              :description => 'Include normal attributes in the output'

            option :long_output,
              :short   => '-l',
              :long    => '--long',
              :boolean => true,
              :default => false,
              :description => 'Include all attributes in the output'
          end
        end
      end

      #==Chef::Knife::Core::StatusPresenter
      # A customized presenter for Chef::Node objects. Supports variable-length
      # output formats for displaying node data
      class StatusPresenter < GenericPresenter

        def format(data)
          if parse_format_option == :json
            summarize_json(data)
          else
            super
          end
        end

        def summarize_json(list)
          result_list = []
          list.each do |node|
            result = {}

            result["name"] = node["name"] || node.name
            result["chef_environment"] = node["chef_environment"]
            ip = (node["ec2"] && node["ec2"]["public_ipv4"]) || node["ipaddress"]
            fqdn = (node["ec2"] && node["ec2"]["public_hostname"]) || node["fqdn"]
            result["ip"] = ip if ip
            result["fqdn"] = fqdn if fqdn
            result["run_list"] = node.run_list if config["run_list"]
            result["ohai_time"] = node["ohai_time"]
            result["platform"] = node["platform"] if node["platform"]
            result["platform_version"] = node["platform_version"] if node["platform_version"]

            if config[:long_output]
              result["default"]   = node.default_attrs
              result["override"]  = node.override_attrs
              result["automatic"] = node.automatic_attrs
            end
            result_list << result
          end

          Chef::JSONCompat.to_json_pretty(result_list)
        end

        # Converts a Chef::Node object to a string suitable for output to a
        # terminal. If config[:medium_output] or config[:long_output] are set
        # the volume of output is adjusted accordingly. Uses colors if enabled
        # in the ui object.
        def summarize(list)
          summarized=''
          list.each do |data|
            node = data
            # special case ec2 with their split horizon whatsis.
            ip = (node[:ec2] && node[:ec2][:public_ipv4]) || node[:ipaddress]
            fqdn = (node[:ec2] && node[:ec2][:public_hostname]) || node[:fqdn]
            name = node['name'] || node.name

            hours, minutes, _ = time_difference_in_hms(node["ohai_time"])
            hours_text   = "#{hours} hour#{hours == 1 ? ' ' : 's'}"
            minutes_text = "#{minutes} minute#{minutes == 1 ? ' ' : 's'}"
            run_list = "#{node['run_list']}" if config[:run_list]
            if hours > 24
              color = :red
              text = hours_text
            elsif hours >= 1
              color = :yellow
              text = hours_text
            else
              color = :green
              text = minutes_text
            end

            line_parts = Array.new
            line_parts << @ui.color(text, color) + ' ago' << name
            line_parts << fqdn if fqdn
            line_parts << ip if ip
            line_parts << run_list if run_list

            if node['platform']
              platform = node['platform']
              if node['platform_version']
                platform << " #{node['platform_version']}"
              end
              line_parts << platform
            end

            summarized=summarized + line_parts.join(', ') + ".\n"
          end
          summarized
        end

        def key(key_text)
          ui.color(key_text, :cyan)
        end

        # :nodoc:
        # TODO: this is duplicated from StatusHelper in the Webui. dedup.
        def time_difference_in_hms(unix_time)
          now = Time.now.to_i
          difference = now - unix_time.to_i
          hours = (difference / 3600).to_i
          difference = difference % 3600
          minutes = (difference / 60).to_i
          seconds = (difference % 60)
          return [hours, minutes, seconds]
        end

      end
    end
  end
end
