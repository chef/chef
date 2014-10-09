#
# Authors:: Bryan McLellan (btm@loftninjas.org)
#           Matthew Landauer (matthew@openaustralia.org)
#           Richard Manyanza (liseki@nyikacraftsmen.com)
#           Scott Bonds (scott@ggr.com)
# Copyright:: Copyright (c) 2009 Bryan McLellan, Matthew Landauer
# Copyright:: Copyright (c) 2014 Richard Manyanza, Scott Bonds
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

require 'chef/resource/package'
require 'chef/provider/package'
require 'chef/mixin/shell_out'
require 'chef/mixin/get_source_from_package'

class Chef
  class Provider
    class Package
      class Openbsd < Chef::Provider::Package
        include Chef::Mixin::ShellOut
        include Chef::Mixin::GetSourceFromPackage

        @@sqlports = nil
        @@repo_packages = nil

        def initialize(*args)
          super
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @new_resource.source("#{mirror}/pub/#{node.kernel.name}/#{node.kernel.release}/packages/#{node.kernel.machine}/") if !@new_resource.source
        end

        def install_package(name, version)
          unless @current_resource.version
            version_string  = ''
            version_string += "-#{version}" if version && version != '0.0.0'
            case @new_resource.source
            when /^http/, /^ftp/
              if @new_resource.source =~ /\/$/
                shell_out!("pkg_add -r #{short_package_name}#{version_string}", :env => { "PACKAGESITE" => @new_resource.source, 'LC_ALL' => nil }).status
              else
                shell_out!("pkg_add -r #{short_package_name}#{version_string}", :env => { "PACKAGEROOT" => @new_resource.source, 'LC_ALL' => nil }).status
              end
              Chef::Log.debug("#{@new_resource} installed from: #{@new_resource.source}")

            when /^\//
              shell_out!("pkg_add #{file_candidate_version_path}", :env => { "PKG_PATH" => @new_resource.source , 'LC_ALL'=>nil}).status
              Chef::Log.debug("#{@new_resource} installed from: #{@new_resource.source}")

            else
              shell_out!("pkg_add -r #{latest_link_name}", :env => nil).status
            end
          end
        end

        def remove_package(name, version)
          version_string  = ''
          version_string += "-#{version}" if version && version != '0.0.0'
          shell_out!("pkg_delete #{short_package_name}#{version_string}", :env => nil).status
        end

        # The name of the package (without the version number) as understood 
        # by pkg_add and pkg_info.
        def short_package_name
          result = ''
          info = find_package(@new_resource.package_name)
          result += info[:short_name]
          if info[:version]
            subpackage = info[:version].match /(.*)-\d.*/
            result += '-' + subpackage[1] if subpackage
          end

          result
        end

        def current_installed_version
          pkg_info = shell_out!("pkg_info -e \"#{short_package_name}->0\"", :env => nil, :returns => [0,1])
          result = pkg_info.stdout[/^inst:#{Regexp.escape(short_package_name)}-(.+)/, 1]
          Chef::Log.debug("current_installed_version of '#{short_package_name}' is '#{result}'")
          result
        end

        def candidate_version
          case @new_resource.source
          when /^http/, /^ftp/
            repo_candidate_version
          when /^\//
            file_candidate_version
          else
            port_candidate_version
          end
        end

        def file_candidate_version_path
          Dir["#{@new_resource.source}/#{@current_resource.package_name}*"][-1].to_s
        end

        def file_candidate_version
          file_candidate_version_path.split(/-/).last.split(/.tbz/).first
        end

        def repo_candidate_version(options={})
          return '0.0.0' if @new_resource.package_name == 'sqlports'
          info = find_package(@new_resource.package_name)
          info[:fullpkgname].sub(/^#{info[:short_name]}-/,'')
        end

        def port_candidate_version
          name = makefile_variable_value("DISTNAME", port_path) || 
            makefile_variable_value("PKGNAME", port_path)
          name.match(/.*?-(\d.*)/)[1]
        end

        # does NOT include port options, i.e. flavors and subpackages
        # i.e. /usr/ports/meta/gnome,-extra ... does NOT include the ',-extra'
        def port_path
          '/usr/ports/' + find_package(@new_resource.package_name)[:fullpkgpath].split(',').first
        end

        def find_package(name)
          return {short_name: 'sqlports'} if name == 'sqlports'

          result = nil

          query = "SELECT fullpkgname, fullpkgpath, pkgspec, pkgname FROM ports WHERE"
          if name.include? '/'
            rows = sqlports.execute "#{query} fullpkgpath = '#{name}'"
            rows = sqlports.execute "#{query} fullpkgpath = '#{name},-main'" if rows.empty?
          else
            rows = sqlports.execute "#{query} fullpkgname = '#{name}'"
            rows = sqlports.execute "#{query} pkgname = '#{name}'" if rows.empty?
            rows = sqlports.execute "#{query} pkgspec = '#{name}-*'" if rows.empty?
          end
          if rows.size > 0
            row = rows.first
            result = {
              short_name: row[2].sub(/-[\*><=].*/,''),
              short_version: row[3].sub(row[2].sub(/[\*><=].*/,''), ''),
              pkgspec: row[2],
              fullpkgname: row[0],
              fullpkgpath: row[1],
           }
          else
            raise Chef::Exceptions::Package, "Could not find a package that matches: #{name}"
          end

          result
        end

        def mirror
          'http://ftp.eu.openbsd.org'
        end

        def sqlports(options={})
          # install the DB that maps ports paths to package names, assume it
          # will stay installed during this chef run, we won't bother to check
          # it on every call to this method
          if !@@sqlports
            Chef::Log.debug("Initializing sqlports")
            shell_out!("pkg_add sqlports") unless ::File.exists?('/usr/local/share/sqlports')
            shell_out!("gem install sqlite3", :returns => [0,1]) unless shell_out!("gem list | grep sqlite3").stdout.include?('sqlite3')
            require 'sqlite3'
            @@sqlports = SQLite3::Database.new '/usr/local/share/sqlports'
          end

          @@sqlports
        end

        def port_dir(port)
          case port

          # When the package name starts with a '/' treat it as the full path to the ports directory.
          when /^\//
            port

          # Otherwise if the package name contains a '/' not at the start (like 'www/wordpress') treat
          # as a relative path from /usr/ports.
          when /\//
            "/usr/ports/#{port}"

          else
            rows = sqlports.execute "SELECT fullpkgpath FROM ports WHERE pkgspec = '#{port}-*';"
            if rows.size > 0
              "/usr/ports/#{rows.first.first.split(',').first}"
            else
              raise Chef::Exceptions::Package, "Could not find port: #{port}"
            end
          end
        end

        def makefile_variable_value(variable, dir = nil)
          options = dir ? { :cwd => dir } : {}
          make_v = shell_out!("make -V #{variable}", options.merge!(:env => nil, :returns => [0,1]))

          # $\ is the line separator, i.e. newline.
          result = make_v.exitstatus.zero? ? make_v.stdout.strip.split($\).first : nil

          # some make variables reference other variables, recurse to resolve
          result = result.gsub(/\${?[A-Z0-9_]*}?/) {|match| makefile_variable_value(match[1..-1].gsub(/[\{\}]/,''), dir)} if result
          result
        end

        def load_current_resource
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(current_installed_version)
          Chef::Log.debug("#{@new_resource} current version is #{@current_resource.version}") if @current_resource.version
          @candidate_version = candidate_version
          Chef::Log.debug("#{@new_resource} candidate version is #{@candidate_version}") if @candidate_version
          @current_resource
        end

      end
    end
  end
end
