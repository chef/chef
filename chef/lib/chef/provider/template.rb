#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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

require 'chef/provider/file'
require 'chef/mixin/template'
require 'chef/mixin/checksum'
require 'chef/file_access_control'

#require 'chef/mixin/find_preferred_file'
#require 'chef/rest'
#require 'chef/file_cache'
#require 'uri'
#require 'tempfile'

class Chef
  class Provider

    class Template < Chef::Provider::File

      include Chef::Mixin::Checksum
      include Chef::Mixin::Template
      #include Chef::Mixin::FindPreferredFile

      def load_current_resource
        super
        @current_resource.checksum(checksum(@current_resource.path)) if ::File.exist?(@current_resource.path)
      end

      def action_create
        render_with_context(template_location) do |rendered_template|
          rendered(rendered_template)
          if ::File.exist?(@new_resource.path) && content_matches?
            Chef::Log.debug("#{@new_resource} content has not changed.")
            set_all_access_controls(@new_resource.path)
          else
            Chef::Log.info("Writing updated content for #{@new_resource} to #{@new_resource.path}")
            backup
            set_all_access_controls(rendered_template.path)
            FileUtils.mv(rendered_template.path, @new_resource.path)
            @new_resource.updated = true
          end
        end
      end

      def action_create_if_missing
        if ::File.exists?(@new_resource.path)
          Chef::Log.debug("Template #{@new_resource} exists, taking no action.")
        else
          action_create
        end
      end

      def template_location
        Chef::Log.debug("looking for template #{@new_resource.source} in cookbook #{cookbook_name.inspect}")
        @template_file_cache_location ||= begin
          if @new_resource.local
            @new_resource.source
          else
            cookbook = run_context.cookbook_collection[resource_cookbook]
            cookbook.preferred_filename_on_disk_location(node, :templates, @new_resource.source)
          end
        end
      end
      
      def resource_cookbook
        @new_resource.cookbook || @new_resource.cookbook_name
      end

      def rendered(rendered_template)
        @new_resource.checksum(checksum(rendered_template.path))
        Chef::Log.debug("Current content's checksum:  #{@current_resource.checksum}")
        Chef::Log.debug("Rendered content's checksum: #{@new_resource.checksum}")
      end

      def content_matches?
        @current_resource.checksum == @new_resource.checksum
      end

      def set_all_access_controls(file)
        access_controls = Chef::FileAccessControl.new(@new_resource, file)
        access_controls.set_all
        @new_resource.updated = access_controls.modified?
      end

      # def locate_or_fetch_template
      #   Chef::Log.debug("looking for template #{@new_resource.source} in cookbook #{cookbook_name.inspect}")
      # 
      #   cache_file_name = "cookbooks/#{cookbook_name}/templates/default/#{@new_resource.source}"
      #   template_cache_name = "#{cookbook_name}_#{@new_resource.source}"
      # 
      #   if @new_resource.local
      #     cache_file_name = @new_resource.source
      #   elsif Chef::Config[:solo]
      #     cache_file_name = solo_cache_file_name
      #   else
      #     raw_template_file = fetch_template_via_rest(cache_file_name, template_cache_name)
      #   end
      # 
      #   if template_updated?
      #     Chef::Log.debug("Updating template for #{@new_resource} in the cache")
      #     Chef::FileCache.move_to(raw_template_file.path, cache_file_name)
      #   end
      #   cache_file_name
      # end

      private

      # def template_updated
      #   @template_updated = true
      # end
      # 
      # def template_not_updated
      #   @template_updated = false
      # end
      # 
      # def template_updated?
      #   @template_updated
      # end
      # 
      # def cookbook_name
      #   @cookbook_name = (@new_resource.cookbook || @new_resource.cookbook_name)
      # end

      def render_with_context(template_location, &block)
        context = {}
        context.merge!(@new_resource.variables)
        context[:node] = node
        render_template(IO.read(template_location), context, &block)
      end

      # def solo_cache_file_name
      #   filename = find_preferred_file(
      #     cookbook_name,
      #     :template,
      #     @new_resource.source,
      #     node[:fqdn],
      #     node[:platform],
      #     node[:platform_version]
      #   )
      #   Chef::Log.debug("Using local file for template:#{filename}")
      #   Pathname.new(filename).relative_path_from(Pathname.new(Chef::Config[:file_cache_path])).to_s
      # end
      # 
      # def fetch_template_via_rest(cache_file_name, template_cache_name)
      #   if node.run_state[:template_cache].has_key?(template_cache_name)
      #     Chef::Log.debug("I have already fetched the template for #{@new_resource} once this run, not checking again.")
      #     template_not_updated
      #     return false
      #   end
      # 
      #   r = Chef::REST.new(Chef::Config[:template_url])
      # 
      #   current_checksum = nil
      # 
      #   if Chef::FileCache.has_key?(cache_file_name)
      #     current_checksum = self.checksum(Chef::FileCache.load(cache_file_name, false))
      #   else
      #     Chef::Log.debug("Template #{@new_resource} is not in the template cache")
      #   end
      # 
      #   template_url = generate_url(@new_resource.source, "templates", :checksum => current_checksum)
      # 
      #   begin
      #     raw_template_file = r.get_rest(template_url, true)
      #     template_updated
      #   rescue Net::HTTPRetriableError
      #     if e.response.kind_of?(Net::HTTPNotModified)
      #       Chef::Log.debug("Cached template for #{@new_resource} is unchanged")
      #     else
      #       raise
      #     end
      #   end
      # 
      #   # We have checked the cache for this template this run
      #   node.run_state[:template_cache][template_cache_name] = true
      # 
      #   raw_template_file
      # end

    end
  end
end
