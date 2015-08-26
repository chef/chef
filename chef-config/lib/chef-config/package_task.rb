#
# Author:: Kartik Null Cating-Subramanian (<ksubramanian@chef.io>)
# Copyright:: Copyright (c) 2015 Chef, Inc.
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

require 'rake'
require 'rubygems'
require 'rubygems/package_task'

module ChefConfig
  class PackageTask < Rake::TaskLib

    # Full path to root of top-level repository.  All other files (like VERSION or
    # lib/<module_path>/version.rb are rooted at this path).
    attr_accessor :root_path

    # Name of the top-level module/library build built.  This is used to define
    # the top level module which contains VERSION and MODULE_ROOT.
    attr_accessor :module_name

    # Should the generated version.rb be in a class or module?  Default is false (module).
    attr_accessor :generate_version_class

    # Paths to the roots of any components that also support ChefPackageTask.
    # If relative paths are provided, they are rooted against root_path.
    attr_accessor :component_paths

    # This is the module name as it appears on the path "lib/module/".
    # e.g. for module_name  "ChefDK", you'd want module_path to be "chef-dk".
    # The default is module_name but lower-cased.
    attr_writer :module_path

    def module_path
      @module_path || module_name.downcase
    end

    # Path to a VERSION file with a single string that contains the package version.
    # By default, this is root_path/VERSION
    attr_accessor :version_file_path

    # Directory used to store package files and output that is generated.
    # This has the same meaning (or lack thereof) as package_dir in
    # rake/packagetask.
    attr_accessor :package_dir

    # Name of git remote used to push tags during a release.  Default is origin.
    attr_accessor :git_remote

    def initialize(root_path=nil, module_name=nil)
      init(root_path, module_name)
      yield self if block_given?
      define unless root_path.nil? || module_name.nil?
    end

    def init(root_path, module_name)
      @root_path = root_path
      @module_name = module_name
      @component_paths = []
      @module_path = nil
      @version_file_path = 'VERSION'
      @package_dir = 'pkg'
      @git_remote = 'origin'
      @generate_version_class = false
    end

    def component_full_paths
      component_paths.map { |path| File.expand_path(path, root_path)}
    end

    def version_rb_path
      File.expand_path("lib/#{module_path}/version.rb", root_path)
    end

    def version
      IO.read(File.expand_path(version_file_path, root_path)).strip
    end

    def full_package_dir
      File.expand_path(package_dir, root_path)
    end

    def class_or_module
      generate_version_class ? 'class' : 'module'
    end

    def with_clean_env(&block)
      if defined?(Bundler)
        Bundler.with_clean_env(&block)
      else
        block.call
      end
    end

    def define
      fail 'Need to provide package root and module name' if root_path.nil? || module_name.nil?

      desc 'Build Gems of component dependencies'
      task :package_components do
        component_full_paths.each do |component_path|
          Dir.chdir(component_path) do
            sh 'rake package'
          end
        end
      end

      task :package => :package_components

      desc 'Build and install component dependencies'
      task :install_components => :package_components do
        component_full_paths.each do |component_path|
          Dir.chdir(component_path) do
            sh 'rake install'
          end
        end
      end

      task :install => :install_components

      desc 'Clean up builds of component dependencies'
      task :clobber_component_packages do
        component_full_paths.each do |component_path|
          Dir.chdir(component_path) do
            sh 'rake clobber_package'
          end
        end
      end

      task :clobber_package => :clobber_component_packages

      desc 'Update the version number for component dependencies'
      task :update_components_versions do
        component_full_paths.each do |component_path|
          Dir.chdir(component_path) do
            sh 'rake version'
          end
        end
      end

      desc 'Regenerate lib/#{@module_path}/version.rb from VERSION file'
      task :version => :update_components_versions do
        contents = <<-VERSION_RB
# Copyright:: Copyright (c) 2010-2015 Chef Software, Inc.
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

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: This file is generated by running `rake version` in the top level of
# this repo. Do not edit this manually. Edit the VERSION file and run the rake
# task instead.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#{class_or_module} #{module_name}
  #{module_name.upcase}_ROOT = File.dirname(File.expand_path(File.dirname(__FILE__)))
  VERSION = '#{version}'
end

#
# NOTE: the Chef::Version class is defined in version_class.rb
#
# NOTE: DO NOT Use the Chef::Version class on #{module_name}::VERSIONs.  The
#       Chef::Version class is for _cookbooks_ only, and cannot handle
#       pre-release versions like "10.14.0.rc.2".  Please use Rubygem's
#       Gem::Version class instead.
#
        VERSION_RB
        IO.write(version_rb_path, contents)
      end

      Dir[File.expand_path("*gemspec", root_path)].reverse.each do |gemspec_path|
        gemspec = eval(IO.read(gemspec_path))
        Gem::PackageTask.new(gemspec) do |task|
          task.package_dir = full_package_dir
        end
      end

      desc "Build and install a #{module_path} gem"
      task :install => [:package] do
        with_clean_env do
          full_module_path = File.join(full_package_dir, module_path)
          sh %{gem install #{full_module_path}-#{version}.gem --no-rdoc --no-ri}
        end
      end

      task :uninstall do
        sh %{gem uninstall #{module_path} -x -v #{version} }
      end

      desc 'Build it, tag it and ship it'
      task :ship => [:clobber_package, :gem] do
        sh("git tag #{version}")
        sh("git push #{git_remote} --tags")
        Dir[File.expand_path('*.gem', full_package_dir)].reverse.each do |built_gem|
          sh("gem push #{built_gem}")
        end
      end
    end
  end

end
