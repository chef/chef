#
# Author:: Christopher Walters (<cw@opscode.com>)
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

module Merb
  module TarballHelper

    class FileParameterException < StandardError ; end

    def validate_file_parameter(cookbook_name, file_param)
      raise FileParameterException, "missing required parameter: file" unless file_param
      raise FileParameterException, "invalid parameter: file must be a File" unless file_param.respond_to?(:has_key?) && file_param[:tempfile].respond_to?(:read)
      tarball_path = file_param[:tempfile].path
      raise FileParameterException, "invalid tarball: (try creating with 'tar czf cookbook.tar.gz cookbook/')" unless system("tar", "tzf", tarball_path)
      entry_roots = `tar tzf #{tarball_path}`.split("\n").map{|e|(e.split('/')-['.']).first}.uniq
      raise FileParameterException, "invalid tarball: tarball root must contain #{cookbook_name}" unless entry_roots.include?(cookbook_name)
    end

    def sandbox_base
      Chef::Config.sandbox_path
    end

    def sandbox_location(sandbox_guid)
      File.join(sandbox_base, sandbox_guid)
    end

    def sandbox_checksum_location(sandbox_guid, checksum)
      File.join(sandbox_location(sandbox_guid), checksum)
    end

    def cookbook_base
      [Chef::Config.cookbook_path].flatten.first
    end

    def cookbook_location(cookbook_name)
      File.join(cookbook_base, cookbook_name)
    end

    def cookbook_base
      [Chef::Config.cookbook_path].flatten.first
    end

    def cookbook_location(cookbook_name)
      File.join(cookbook_base, cookbook_name)
    end

    def cookbook_location(cookbook_name)
      File.join(cookbook_base, cookbook_name)
    end

    def get_or_create_cookbook_tarball_location(cookbook_name)
      tarball_location = cookbook_tarball_location(cookbook_name)
      unless File.exists? tarball_location
        args = ["tar", "-C", cookbook_base, "-czf", tarball_location, cookbook_name]
        Chef::Log.debug("Tarball for #{cookbook_name} not found, so creating at #{tarball_location} with '#{args.join(' ')}'")
        FileUtils.mkdir_p(Chef::Config.cookbook_tarball_path)
        system(*args)
      end
      tarball_location
    end

    def expand_tarball_and_put_in_repository(cookbook_name, file)
      # untar cookbook tarball into tempdir
      tempdir = File.join("#{file.path}.data")
      Chef::Log.debug("Creating #{tempdir} and untarring #{file.path} into it")
      FileUtils.mkdir_p(tempdir)
      raise "Could not untar file" unless system("tar", "xzf", file.path, "-C", tempdir)

      cookbook_path = cookbook_location(cookbook_name)
      tarball_path = cookbook_tarball_location(cookbook_name)

      # clear any existing cookbook components and move tempdir into the repository
      Chef::Log.debug("Moving #{tempdir} to #{cookbook_path}")
      FileUtils.rm_rf(cookbook_path)
      FileUtils.mkdir_p(cookbook_path)
      Dir[File.join(tempdir, cookbook_name, "*")].each{|e| FileUtils.mv(e, cookbook_path)}

      # clear the existing tarball (if exists) and move the downloaded tarball to the cache
      Chef::Log.debug("Moving #{file.path} to #{tarball_path}")
      FileUtils.mkdir_p(Chef::Config.cookbook_tarball_path)
      FileUtils.rm_f(tarball_path)
      FileUtils.mv(file.path, tarball_path)
    end

  end
end
