#
# Author:: Adam Jacob (<adam@opscode.com>)
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
    class CookbookDelete < Knife
      
      option :all, :short => '-a', :long => '--all', :boolean => true, :description => 'delete all versions'

      banner "Sub-Command: cookbook delete COOKBOOK VERSION (options)"

      def run
        @cookbook_name, @version = name_args
        if @cookbook_name && @version
          delete_explicit_version
        elsif @cookbook_name && config[:all]
          delete_all_versions
        elsif @cookbook_name && @version.nil?
          delete_without_explicit_version
        elsif @cookbook_name.nil?
          # fail
        end
      end

      def delete_explicit_version
        delete_object(Chef::CookbookVersion, "#{@cookbook_name} version #{@version}", "cookbook") do
          rest.delete_rest("cookbooks/#{@cookbook_name}/#{@version}")
        end
      end

      def delete_all_versions
        confirm("Do you really want to delete all versions of #{@cookbook_name}")
        delete_all_without_confirmation
      end

      def delete_all_without_confirmation
        # look up the available versions again just in case the user
        # got to the list of versions to delete and selected 'all'
        # and also a specific version
        @available_versions = nil
        available_versions.each do |version|
          delete_version_without_confirmation(version)
        end
      end

      def delete_without_explicit_version
        if available_versions.size == 1
          @version = available_versions.first
          delete_explicit_version
        else
          versions_to_delete = ask_which_versions_to_delete
          delete_versions_without_confirmation(versions_to_delete)
        end
      end

      def available_versions
        @available_versions ||= rest.get_rest("cookbooks/#{@cookbook_name}").values.flatten
      rescue Net::HTTPServerException => e
        if e.to_s =~ /^404/
          Chef::Log.error("Cannot find a cookbook named #{@cookbook_name} to delete")
        else
          raise
        end
      end

      def ask_which_versions_to_delete
        question = "Which version(s) do you want to delete?\n"
        valid_responses = {}
        available_versions.each_with_index do |version, index|
          valid_responses[(index + 1).to_s] = version
          question << "#{index + 1}. #{@cookbook_name} #{version}\n"
        end
        valid_responses[(available_versions.size + 1).to_s] = :all
        question << "#{available_versions.size + 1}. All versions\n\n"
        responses = ask_question(question).split(',').map { |response| response.strip }
        
        if responses.empty?
          Chef::Log.error("No versions specified, exiting")
          exit(1)
        end
        versions = responses.map do |response|
          if version = valid_responses[response]
            version
          else
            Chef::Log.error("#{response} is not a valid choice, skipping it")
          end
        end
        versions.compact
      end

      def delete_version_without_confirmation(version)
        object = rest.delete_rest("cookbooks/#{@cookbook_name}/#{version}")
        output(format_for_display(object)) if config[:print_after]
        Chef::Log.info("Deleted cookbook[#{@cookbook_name}][#{version}]")
      end

      def delete_versions_without_confirmation(versions)
        versions.each do |version|
          if version == :all
            delete_all_without_confirmation
            break
          else
            delete_version_without_confirmation(version)
          end
        end
      end

    end
  end
end
