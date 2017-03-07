#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

require "chef/resource"
require "chef/dsl/declare_resource"
require "chef/mixin/shell_out"
require "chef/mixin/which"
require "chef/http/simple"
require "chef/provider/noop"

class Chef
  class Provider
    class AptRepository < Chef::Provider
      use_inline_resources

      include Chef::Mixin::ShellOut
      extend Chef::Mixin::Which

      provides :apt_repository do
        which("apt-get")
      end

      def whyrun_supported?
        true
      end

      def load_current_resource
      end

      action :add do
        unless new_resource.key.nil?
          if is_key_id?(new_resource.key) && !has_cookbook_file?(new_resource.key)
            install_key_from_keyserver
          else
            install_key_from_uri
          end
        end

        declare_resource(:execute, "apt-cache gencaches") do
          ignore_failure true
          action :nothing
        end

        declare_resource(:apt_update, new_resource.name) do
          ignore_failure true
          action :nothing
        end

        components = if is_ppa_url?(new_resource.uri) && new_resource.components.empty?
                       "main"
                     else
                       new_resource.components
                     end

        repo = build_repo(
          new_resource.uri,
          new_resource.distribution,
          components,
          new_resource.trusted,
          new_resource.arch,
          new_resource.deb_src
        )

        declare_resource(:file, "/etc/apt/sources.list.d/#{new_resource.name}.list") do
          owner "root"
          group "root"
          mode "0644"
          content repo
          sensitive new_resource.sensitive
          action :create
          notifies :run, "execute[apt-cache gencaches]", :immediately
          notifies :update, "apt_update[#{new_resource.name}]", :immediately if new_resource.cache_rebuild
        end
      end

      action :remove do
        if ::File.exist?("/etc/apt/sources.list.d/#{new_resource.name}.list")
          converge_by "Removing #{new_resource.name} repository from /etc/apt/sources.list.d/" do
            declare_resource(:file, "/etc/apt/sources.list.d/#{new_resource.name}.list") do
              sensitive new_resource.sensitive
              action :delete
              notifies :update, "apt_update[#{new_resource.name}]", :immediately if new_resource.cache_rebuild
            end

            declare_resource(:apt_update, new_resource.name) do
              ignore_failure true
              action :nothing
            end

          end
        end
      end

      def is_key_id?(id)
        id = id[2..-1] if id.start_with?("0x")
        id =~ /^\h+$/ && [8, 16, 40].include?(id.length)
      end

      def extract_fingerprints_from_cmd(cmd)
        so = shell_out(cmd)
        so.run_command
        so.stdout.split(/\n/).map do |t|
          if z = t.match(/^fpr:+([0-9A-F]+):/)
            z[1].split.join
          end
        end.compact
      end

      def key_is_valid?(cmd, key)
        valid = true

        so = shell_out(cmd)
        so.run_command
        so.stdout.split(/\n/).map do |t|
          if t =~ %r{^\/#{key}.*\[expired: .*\]$}
            Chef::Log.debug "Found expired key: #{t}"
            valid = false
            break
          end
        end

        Chef::Log.debug "key #{key} #{valid ? "is valid" : "is not valid"}"
        valid
      end

      def cookbook_name
        new_resource.cookbook || new_resource.cookbook_name
      end

      def has_cookbook_file?(fn)
        run_context.has_cookbook_file_in_cookbook?(cookbook_name, fn)
      end

      def no_new_keys?(file)
        # Now we are using the option --with-colons that works across old os versions
        # as well as the latest (16.10). This for both `apt-key` and `gpg` commands
        installed_keys = extract_fingerprints_from_cmd("apt-key adv --list-public-keys --with-fingerprint --with-colons")
        proposed_keys = extract_fingerprints_from_cmd("gpg --with-fingerprint --with-colons #{file}")
        (installed_keys & proposed_keys).sort == proposed_keys.sort
      end

      def install_key_from_uri
        key_name = new_resource.key.gsub(/[^0-9A-Za-z\-]/, "_")
        cached_keyfile = ::File.join(Chef::Config[:file_cache_path], key_name)
        type = if new_resource.key.start_with?("http")
                 :remote_file
               elsif has_cookbook_file?(new_resource.key)
                 :cookbook_file
               else
                 raise Chef::Exceptions::FileNotFound, "Cannot locate key file"
               end

        declare_resource(type, cached_keyfile) do
          source new_resource.key
          mode "0644"
          sensitive new_resource.sensitive
          action :create
        end

        raise "The key #{cached_keyfile} is invalid and cannot be used to verify an apt repository." unless key_is_valid?("gpg #{cached_keyfile}", "")

        declare_resource(:execute, "apt-key add #{cached_keyfile}") do
          sensitive new_resource.sensitive
          action :run
          not_if do
            no_new_keys?(cached_keyfile)
          end
          notifies :run, "execute[apt-cache gencaches]", :immediately
        end
      end

      def install_key_from_keyserver(key = new_resource.key, keyserver = new_resource.keyserver)
        cmd = "apt-key adv --recv"
        cmd << " --keyserver-options http-proxy=#{new_resource.key_proxy}" if new_resource.key_proxy
        cmd << " --keyserver "
        cmd << if keyserver.start_with?("hkp://")
                 keyserver
               else
                 "hkp://#{keyserver}:80"
               end

        cmd << " #{key}"

        declare_resource(:execute, "install-key #{key}") do
          command cmd
          sensitive new_resource.sensitive
          not_if do
            present = extract_fingerprints_from_cmd("apt-key finger").any? do |fp|
              fp.end_with? key.upcase
            end
            present && key_is_valid?("apt-key list", key.upcase)
          end
          notifies :run, "execute[apt-cache gencaches]", :immediately
        end

        raise "The key #{key} is invalid and cannot be used to verify an apt repository." unless key_is_valid?("apt-key list", key.upcase)
      end

      def install_ppa_key(owner, repo)
        url = "https://launchpad.net/api/1.0/~#{owner}/+archive/#{repo}"
        key_id = Chef::HTTP::Simple.new(url).get("signing_key_fingerprint").delete('"')
        install_key_from_keyserver(key_id, "keyserver.ubuntu.com")
      rescue Net::HTTPServerException => e
        raise "Could not access Launchpad ppa API: #{e.message}"
      end

      def is_ppa_url?(url)
        url.start_with?("ppa:")
      end

      def make_ppa_url(ppa)
        return unless is_ppa_url?(ppa)
        owner, repo = ppa[4..-1].split("/")
        repo ||= "ppa"

        install_ppa_key(owner, repo)
        "http://ppa.launchpad.net/#{owner}/#{repo}/ubuntu"
      end

      def build_repo(uri, distribution, components, trusted, arch, add_src = false)
        uri = make_ppa_url(uri) if is_ppa_url?(uri)

        uri = '"' + uri + '"' unless uri.start_with?("'", '"')
        components = Array(components).join(" ")
        options = []
        options << "arch=#{arch}" if arch
        options << "trusted=yes" if trusted
        optstr = unless options.empty?
                   "[" + options.join(" ") + "]"
                 end
        info = [ optstr, uri, distribution, components ].compact.join(" ")
        repo =  "deb      #{info}\n"
        repo << "deb-src  #{info}\n" if add_src
        repo
      end
    end
  end
end

Chef::Provider::Noop.provides :apt_repository
