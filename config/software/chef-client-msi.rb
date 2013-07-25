#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

name "chef-client-msi"

source :path => File.expand_path("files/msi", Omnibus.project_root)

build do
  # harvest with heat.exe
  # recursively generate fragment for chef-client directory
  block do
    src_dir = self.project_dir

    shell = Mixlib::ShellOut.new("heat.exe dir \"#{install_dir}\" -nologo -srd -gg -cg ChefClientDir -dr CHEFLOCATION -var var.ChefClientSourceDir -out chef-client-Files.wxs", :cwd => src_dir)
    shell.run_command
    shell.error!
  end

  # Prepare the include file which contains the version numbers
  block do
    require 'erb'

    File.open("#{project_dir}\\templates\\chef-client-Config.wxi.erb") { |file|
      # build_version looks something like this:
      # dev builds => 0.10.8-299-g360818f
      # rel builds => 0.10.8-299
      versions = build_version.split("-").first.split(".")
      @major_version = versions[0]
      @minor_version = versions[1]
      @micro_version = versions[2]
      @build_version = build_version.split("-")[1] || self.project.build_iteration

      # Find path in which chef gem is installed to.
      # Note that install_dir is something like: c:\\opscode\\chef
      chef_path_regex = "#{install_dir.gsub(File::ALT_SEPARATOR, File::SEPARATOR)}/**/gems/chef-[0-9]*"
      chef_gem_paths = Dir[chef_path_regex].select{ |path| File.directory?(path) }
      raise "Expected one but found #{chef_gem_paths.length} installation directories for chef gem using: #{chef_path_regex}. Found paths: #{chef_gem_paths.inspect}." unless chef_gem_paths.length == 1
      @chef_gem_path = chef_gem_paths.first

      # Convert the chef gem path to a relative path based on install_dir
      # We are going to use this path in the startup command of chef
      # service. So we need to change file seperators to make windows
      # happy.
      @chef_gem_path.gsub!(File::SEPARATOR, File::ALT_SEPARATOR)
      @chef_gem_path.slice!(install_dir.gsub(File::SEPARATOR, File::ALT_SEPARATOR) + File::ALT_SEPARATOR)

      @guid = "D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5"

      erb = ERB.new(file.read)
      File.open("#{project_dir}\\ChefClient-Config.wxi", "w") { |out|
        out.write(erb.result(binding))
      }
    }
  end

  # Create temporary directory to store the files required for msi
  # packaging.
  command "IF exist #{install_dir}\\msi-tmp (echo msi-tmp is found on the system) ELSE (mkdir #{install_dir}\\msi-tmp && echo msi-tmp directory is created.) "

  # Copy the localization file into the temporary file directory for packaging
  command "xcopy chef-client-en-us.wxl #{install_dir}\\msi-tmp /Y", :cwd => source[:path]

  # Copy the asset files into the temporary file directory for packaging
  command "xcopy assets #{install_dir}\\msi-tmp\\assets /I /Y", :cwd => source[:path]

  # compile with candle.exe
  block do
    src_dir = self.project_dir

    shell = Mixlib::ShellOut.new("candle.exe -nologo -out #{install_dir}\\msi-tmp\\ -dChefClientSourceDir=\"#{install_dir}\" chef-client-Files.wxs chef-client.wxs", :cwd => src_dir)
    shell.run_command
    shell.error!
  end
end
