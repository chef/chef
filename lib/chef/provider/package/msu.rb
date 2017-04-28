#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

# msu_package leverages cab_package
# The contents of msu file are extracted, which contains one or more cab files.
# The extracted cab files are installed using Chef::Resource::Package::CabPackage
# Reference: https://support.microsoft.com/en-in/kb/934307
require "chef/provider/package"
require "chef/resource/msu_package"
require "chef/mixin/shell_out"
require "chef/provider/package/cab"
require "chef/util/path_helper"
require "chef/mixin/uris"
require "chef/mixin/checksum"

class Chef
  class Provider
    class Package
      class Msu < Chef::Provider::Package
        include Chef::Mixin::ShellOut
        include Chef::Mixin::Uris
        include Chef::Mixin::Checksum

        provides :msu_package, os: "windows"

        def load_current_resource
          @current_resource = Chef::Resource::MsuPackage.new(new_resource.name)

          # download file if source is a url
          msu_file = uri_scheme?(new_resource.source) ? download_source_file : new_resource.source

          # temp directory where the contents of msu file get extracted
          @temp_directory = Dir.mktmpdir("chef")
          extract_msu_contents(msu_file, @temp_directory)
          @cab_files = read_cab_files_from_xml(@temp_directory)

          if @cab_files.empty?
            raise Chef::Exceptions::Package, "Corrupt MSU package: MSU package XML does not contain any cab file"
          else
            current_resource.version(get_current_versions)
          end
          current_resource
        end

        def get_current_versions
          @cab_files.map do |cabfile|
            cab_pkg = get_cab_package(cabfile)
            cab_pkg.installed_version
          end
        end

        def get_candidate_versions
          @cab_files.map do |cabfile|
            cab_pkg = get_cab_package(cabfile)
            cab_pkg.package_version
          end
        end

        def candidate_version
          @candidate_version ||= get_candidate_versions
        end

        def get_cab_package(cab_file)
          cab_resource = new_resource
          cab_resource.source = cab_file
          Chef::Provider::Package::Cab.new(cab_resource, nil)
        end

        def download_source_file
          source_resource.run_action(:create)
          Chef::Log.debug("#{new_resource} fetched source file to #{source_resource.path}")
          source_resource.path
        end

        def source_resource
          @source_resource ||= declare_resource(:remote_file, new_resource.name) do
            path default_download_cache_path
            source new_resource.source
            checksum new_resource.checksum
            backup false
          end
        end

        def default_download_cache_path
          uri = ::URI.parse(new_resource.source)
          filename = ::File.basename(::URI.unescape(uri.path))
          file_cache_dir = Chef::FileCache.create_cache_path("package/")
          Chef::Util::PathHelper.cleanpath("#{file_cache_dir}/#{filename}")
        end

        def install_package(name, version)
          # use cab_package resource to install the extracted cab packages
          @cab_files.each do |cab_file|
            declare_resource(:cab_package, new_resource.name) do
              source cab_file
              action :install
            end
          end
        end

        def remove_package(name, version)
          # use cab_package provider to remove the extracted cab packages
          @cab_files.each do |cab_file|
            declare_resource(:cab_package, new_resource.name) do
              source cab_file
              action :remove
            end
          end
        end

        def extract_msu_contents(msu_file, destination)
          with_os_architecture(nil) do
            shell_out_with_timeout!("#{ENV['SYSTEMROOT']}\\system32\\expand.exe -f:* #{msu_file} #{destination}")
          end
        end

        # msu package can contain multiple cab files
        # Reading cab files from xml to ensure the order of installation in case of multiple cab files
        def read_cab_files_from_xml(msu_dir)
          # get the file with .xml extension
          xml_files = Dir.glob("#{msu_dir}/*.xml")
          cab_files = []

          if xml_files.empty?
            raise Chef::Exceptions::Package, "Corrupt MSU package: MSU package doesn't contain any xml file"
          else
            # msu package contains only single xml file. So using xml_files.first is sufficient
            doc = ::File.open(xml_files.first.to_s) { |f| REXML::Document.new f }
            locations = doc.elements.each("unattend/servicing/package/source") { |element| element.attributes["location"] }
            locations.each do |loc|
              cab_files << msu_dir + "/" + loc.attribute("location").value.split("\\")[1]
            end

            cab_files
          end
          cab_files
        end

        def cleanup_after_converge
          # delete the temp directory where the contents of msu file are extracted
          FileUtils.rm_rf(@temp_directory) if Dir.exist?(@temp_directory)
        end
      end
    end
  end
end
