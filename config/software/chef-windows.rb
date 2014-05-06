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

name "chef-windows"

dependency "ruby-windows" #includes rubygems
dependency "libyaml-windows"
dependency "ruby-windows-devkit"
dependency "bundler"
dependency "cacerts"

default_version "master"

source :git => "git://github.com/opscode/chef"

relative_path "chef"

always_build (self.project.name == "chef-windows")

build do
  # Nasty hack to set the artifact version until this gets fixed:
  # https://github.com/opscode/omnibus-ruby/issues/134
  block do
    project = self.project
    if project.name == "chef-windows"
      project.build_version Omnibus::BuildVersion.new(self.project_dir).semver
    end
  end

  # COMPAT HACK :( - Chef 11 finally has the core Chef code in the root of the
  # project repo. Since the Chef Client pipeline needs to build/test Chef 10.x
  # and 11 releases our software definition need to handle both cases
  # gracefully.
  block do
    build_commands = self.builder.build_commands
    chef_root = File.join(self.project_dir, "chef")
    if File.exists?(chef_root)
      build_commands.each_index do |i|
        cmd = build_commands[i].dup
        if cmd.is_a? Array
          if cmd.last.is_a? Hash
            cmd_opts = cmd.pop.dup
            cmd_opts[:cwd] = chef_root
            cmd << cmd_opts
          else
            cmd << {:cwd => chef_root}
          end
          build_commands[i] = cmd
        end
      end
    end
  end

  # Normally we would symlink the required unix tools.
  # However with the introduction of git-cache to speed up omnibus builds,
  # we can't do that anymore since git on windows doesn't support symlinks.
  # https://groups.google.com/forum/#!topic/msysgit/arTTH5GmHRk
  # Therefore we copy the tools to the necessary places.
  # We need tar for 'knife cookbook site install' to function correctly
  {"tar.exe" => "bsdtar.exe",
    "libarchive-2.dll" => "libarchive-2.dll",
    "libexpat-1.dll" => "libexpat-1.dll",
    "liblzma-1.dll" => "liblzma-1.dll",
    "libbz2-2.dll" => "libbz2-2.dll",
    "libz-1.dll" => "libz-1.dll"
  }.each do |target, to|
    source = File.expand_path(File.join(install_dir, "embedded", "mingw", "bin", to)).gsub(/\//, "\\")
    target = File.expand_path(File.join(install_dir, "bin", target)).gsub(/\//, "\\")
    command "cp #{source}  #{target}"
  end

  rake "gem"

  gem ["install pkg/chef*mingw32.gem",
       "-n #{install_dir}/bin",
       "--no-rdoc --no-ri"].join(" ")

  # XXX: doing a normal bundle_bust here results in gems installed into the outer bundle...
  command "bundle install", :env => { "PATH" => "#{install_dir}/embedded/bin;#{install_dir}/embedded/mingw/bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem", "BUNDLE_BIN_PATH" => "#{install_dir}/embedded/bin/bundle" , "BUNDLE_GEMFILE" => nil, "GEM_HOME" => "#{install_dir}/embedded/lib/ruby/gems/1.9.1", "GEM_PATH" => "#{install_dir}/embedded/lib/ruby/gems/1.9.1", "RUBYOPT" => nil }

  # render batch files
  #
  # TODO:
  #  I'd love to move this out to a top-level 'template' operation in omnibus, but it currently
  #  requires pretty deep inspection of the Rubygems structure of the installed chef and ohai
  #  gems
  #
  block do
    require 'erb'
    require 'rubygems/format'

    batch_template = ERB.new <<EOBATCH
@ECHO OFF
IF NOT "%~f0" == "~f0" GOTO :WinNT
@"%~dp0\\..\\embedded\\bin\\ruby.exe" "%~dp0/<%= @bin %>" %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF
:WinNT
@"%~dp0\\..\\embedded\\bin\\ruby.exe" "%~dpn0" %*
EOBATCH

    gem_executables = []
    %w{chef}.each do |gem|
      puts "#{install_dir.gsub(/\\/, '/')}/embedded/**/cache/#{gem}*mingw32.gem"
      require 'pp'
      pp Dir["#{install_dir.gsub(/\\/, '/')}/embedded/**/cache/#{gem}*mingw32.gem"]
      gem_file = Dir["#{install_dir.gsub(/\\/, '/')}/embedded/**/cache/#{gem}*mingw32.gem"].first
      gem_executables << Gem::Format.from_file_by_path(gem_file).spec.executables
    end

    # XXX: need to fix ohai to use own gemspec as well and eliminate copypasta
    %w{ohai}.each do |gem|
      gem_file = Dir["#{install_dir.gsub(/\\/, '/')}/embedded/**/cache/#{gem}*.gem"].first
      gem_executables << Gem::Format.from_file_by_path(gem_file).spec.executables
    end

    gem_executables.flatten.each do |bin|
      @bin = bin
      File.open("#{install_dir}/bin/#{@bin}.bat", "w") do |f|
        f.puts batch_template.result(binding)
      end
    end
  end
end
