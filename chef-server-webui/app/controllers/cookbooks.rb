#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2008-2011 Opscode, Inc.
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

require 'chef/cookbook_loader'
require 'chef/cookbook_version'

class Cookbooks < Application

  provides :html
  before :login_required
  before :params_helper

  attr_reader :cookbook_id
  def params_helper
    @cookbook_id = params[:id] || params[:cookbook_id]
  end

  def index
    @cl = fetch_cookbook_versions(6)
    display @cl
  end

  def show
    begin
      all_books = fetch_cookbook_versions("all", :cookbook => cookbook_id)
      @versions = all_books[cookbook_id].map { |v| v["version"] }
      if params[:cb_version] == "_latest"
        redirect(url(:show_specific_version_cookbook,
                     :cookbook_id => cookbook_id,
                     :cb_version => @versions.first))
        return
      end
      @version = params[:cb_version]
      if !@versions.include?(@version)
        msg = { :warning => ["Cookbook #{cookbook_id} (#{params[:cb_version]})",
                             "is not available in the #{session[:environment]}",
                             "environment."
                            ].join(" ") }
        redirect(url(:cookbooks), :message => msg)
        return
      end
      cookbook_url = "cookbooks/#{cookbook_id}/#{@version}"
      rest = Chef::REST.new(Chef::Config[:chef_server_url])
      @cookbook = rest.get_rest(cookbook_url)
      raise NotFound unless @cookbook
      @manifest = @cookbook.manifest
      display @cookbook
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = {:error => $!}
      @cl = {}
      render :index
    end
  end

  # GET /cookbooks/cookbook_id
  # provides :json, for the javascript on the environments web form.
  def cb_versions
    provides :json
    use_envs = session[:environment] && !params[:ignore_environments]
    num_versions = params[:num_versions] || "all"
    all_books = fetch_cookbook_versions(num_versions, :cookbook => cookbook_id,
                                        :use_envs => use_envs)
    display({ cookbook_id => all_books[cookbook_id] })
  end

  ## ------
  ## Helpers
  ##
  ## TODO: move these to a cookbooks helper module
  ## ------

  def recipe_files
    # node = params.has_key?('node') ? params[:node] : nil
    # @recipe_files = load_all_files(:recipes, node)
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    @recipe_files = r.get_rest("cookbooks/#{params[:id]}/recipes")
    display @recipe_files
  end

  def attribute_files
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    @recipe_files = r.get_rest("cookbooks/#{params[:id]}/attributes")
    display @attribute_files
  end

  def definition_files
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    @recipe_files = r.get_rest("cookbooks/#{params[:id]}/definitions")
    display @definition_files
  end

  def library_files
    r = Chef::REST.new(Chef::Config[:chef_server_url])
    @recipe_files = r.get_rest("cookbooks/#{params[:id]}/libraries")
    display @lib_files
  end

  def more_versions_link(cookbook)
    link_to("+", "JavaScript:void(0);",
            :title => "show other versions of #{cookbook}",
            :data => cookbook,
            :class => "cookbook_version_toggle")
  end

  def all_versions_link(cookbook)
    link_to("show all versions...", "JavaScript:void(0);",
            :class => "show_all",
            :id => "#{cookbook}_show_all",
            :data => cookbook,
            :title => "show all versions of #{cookbook}")
  end

  def cookbook_link(version)
    url(:show_specific_version_cookbook,
        :cookbook_id => @cookbook_id, :cb_version => version)
  end

  def cookbook_parts
    Chef::CookbookVersion::COOKBOOK_SEGMENTS.map do |p|
      part = p.to_s
      case part
      when "files"
        [part, "plain"]
      else
        [part, "ruby"]
      end
    end.sort { |a, b| a[0] <=> b[0] }
  end

  def highlight_content(url, type)
    case type
    when "plain"
      show_plain_file(url)
    else
      begin
        syntax_highlight(url)
      rescue
        Chef::Log.error("Error while parsing file #{url}")
      end
    end
  end

  private

  def fetch_cookbook_versions(num_versions, options={})
    opts = { :use_envs => true, :cookbook => nil }.merge(options)
    url = if opts[:use_envs]
            env = session[:environment] || "_default"
            "environments/#{env}/cookbooks"
          else
            "cookbooks"
          end
    # we want to display at most 5 versions, but we ask for 6.  This
    # tells us if we should display a 'show all' button or not.
    url += "/#{opts[:cookbook]}" if opts[:cookbook]
    url += "?num_versions=#{num_versions}"
    begin
      result = Chef::REST.new(Chef::Config[:chef_server_url]).get_rest(url)
      result.inject({}) do |ans, (name, cb)|
        cb["versions"].each do |v|
          v["url"] = url(:show_specific_version_cookbook, :cookbook_id => name,
                         :cb_version => v["version"])
        end
        ans[name] = cb["versions"]
        ans
      end
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @_message = {:error => $!}
      {}
    end
  end

end
