#
# Author:: Kartik Null Cating-Subramanian (<ksubramanian@chef.io>)
# Copyright:: Copyright 2015-2016, Chef, Inc.
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

require "rake"
require "rubygems"
require "rubygems/package_task"

module ChefConfig
  class PackageTask < Rake::TaskLib

    # Full path to root of top-level repository.  All other files (like VERSION or
    # lib/<module_path>/version.rb are rooted at this path).
    attr_accessor :root_path

    # Name of the top-level module/library build built.  This is used to define
    # the top level module which contains VERSION and MODULE_ROOT.
    attr_accessor :module_name

    # Name of the gem being built. This is used to find the lines to fix in
    # Gemfile.lock.
    attr_accessor :gem_name

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

    # Directory used to store package files and output that is generated.
    # This has the same meaning (or lack thereof) as package_dir in
    # rake/packagetask.
    attr_accessor :package_dir

    # Name of git remote used to push tags during a release.  Default is origin.
    attr_accessor :git_remote

    def initialize(root_path = nil, module_name = nil, gem_name = nil)
      init(root_path, module_name, gem_name)
      yield self if block_given?
      define unless root_path.nil? || module_name.nil?
    end

    def init(root_path, module_name, gem_name)
      @root_path = root_path
      @module_name = module_name
      @gem_name = gem_name
      @component_paths = []
      @module_path = nil
      @package_dir = "pkg"
      @git_remote = "origin"
      @generate_version_class = false
    end

    def component_full_paths
      component_paths.map { |path| File.expand_path(path, root_path) }
    end

    def version_rb_path
      File.expand_path("lib/#{module_path}/version.rb", root_path)
    end

    def chef_root_path
      module_name == "Chef" ? root_path : File.dirname(root_path)
    end

    def version_file_path
      File.join(chef_root_path, "VERSION")
    end

    def gemfile_lock_path
      File.join(root_path, "Gemfile.lock")
    end

    def version
      IO.read(version_file_path).strip
    end

    def full_package_dir
      File.expand_path(package_dir, root_path)
    end

    def class_or_module
      generate_version_class ? "class" : "module"
    end

    def with_clean_env(&block)
      if defined?(Bundler)
        Bundler.with_clean_env(&block)
      else
        yield
      end
    end

    def define
      raise "Need to provide package root and module name" if root_path.nil? || module_name.nil?

      desc "Build Gems of component dependencies"
      task :package_components do
        component_full_paths.each do |component_path|
          Dir.chdir(component_path) do
            sh "rake package"
          end
        end
      end

      task :package => :package_components

      desc "Build and install component dependencies"
      task :install_components => :package_components do
        component_full_paths.each do |component_path|
          Dir.chdir(component_path) do
            sh "rake install"
          end
        end
      end

      task :install => :install_components

      desc "Clean up builds of component dependencies"
      task :clobber_component_packages do
        component_full_paths.each do |component_path|
          Dir.chdir(component_path) do
            sh "rake clobber_package"
          end
        end
      end

      task :clobber_package => :clobber_component_packages

      desc "Update the version number for component dependencies"
      task :update_components_versions do
        component_full_paths.each do |component_path|
          Dir.chdir(component_path) do
            sh "rake version"
          end
        end
      end

      namespace :version do
        desc 'Regenerate lib/#{@module_path}/version.rb from VERSION file'
        task :update => :update_components_versions do
          update_version_rb
          update_gemfile_lock
        end

        task :bump => %w{version:bump_patch version:update}

        task :show do
          puts version
        end

        # Add 1 to the current patch version in the VERSION file, and write it back out.
        task :bump_patch do
          current_version = version
          new_version = current_version.sub(/^(\d+\.\d+\.)(\d+)/) { "#{$1}#{$2.to_i + 1}" }
          puts "Updating version in #{version_rb_path} from #{current_version.chomp} to #{new_version.chomp}"
          IO.write(version_file_path, new_version)
        end

        task :bump_minor do
          current_version = version
          new_version = current_version.sub(/^(\d+)\.(\d+)\.(\d+)/) { "#{$1}.#{$2.to_i + 1}.0" }
          puts "Updating version in #{version_rb_path} from #{current_version.chomp} to #{new_version.chomp}"
          IO.write(version_file_path, new_version)
        end

        task :bump_major do
          current_version = version
          new_version = current_version.sub(/^(\d+)\.(\d+\.\d+)/) { "#{$1.to_i + 1}.0.0" }
          puts "Updating version in #{version_rb_path} from #{current_version.chomp} to #{new_version.chomp}"
          IO.write(version_file_path, new_version)
        end

        def update_version_rb # rubocop:disable Lint/NestedMethodDefinition
          puts "Updating #{version_rb_path} to include version #{version} ..."
          contents = <<-VERSION_RB
# Copyright:: Copyright 2010-2016, Chef Software, Inc.
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
  #{module_name.upcase}_ROOT = File.expand_path("../..", __FILE__)
  VERSION = "#{version}"
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

        def update_gemfile_lock # rubocop:disable Lint/NestedMethodDefinition
          if File.exist?(gemfile_lock_path)
            puts "Updating #{gemfile_lock_path} to include version #{version} ..."
            contents = IO.read(gemfile_lock_path)
            contents.gsub!(/^\s*(chef|chef-config)\s*\((= )?\S+\)\s*$/) do |line|
              line.gsub(/\((= )?\d+(\.\d+)+/) { "(#{$1}#{version}" }
            end
            IO.write(gemfile_lock_path, contents)
          end
        end
      end

      task :version => "version:update"

      gemspec_platform_to_install = ""
      Dir[File.expand_path("*.gemspec", root_path)].reverse_each do |gemspec_path|
        gemspec = eval(IO.read(gemspec_path))
        Gem::PackageTask.new(gemspec) do |task|
          task.package_dir = full_package_dir
        end
        gemspec_platform_to_install = "-#{gemspec.platform}" if gemspec.platform != Gem::Platform::RUBY && Gem::Platform.match(gemspec.platform)
      end

      desc "Build and install a #{module_path} gem"
      task :install => [:package] do
        with_clean_env do
          full_module_path = File.join(full_package_dir, module_path)
          sh %{gem install #{full_module_path}-#{version}#{gemspec_platform_to_install}.gem --no-rdoc --no-ri}
        end
      end

      task :uninstall do
        sh %{gem uninstall #{module_path} -x -v #{version} }
      end

      desc "Build it, tag it and ship it"
      task :ship => [:clobber_package, :gem] do
        sh("git tag #{version}")
        sh("git push #{git_remote} --tags")
        Dir[File.expand_path("*.gem", full_package_dir)].reverse_each do |built_gem|
          sh("gem push #{built_gem}")
        end
      end
    end
  end

end
