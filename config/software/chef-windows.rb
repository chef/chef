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

dependencies ["ruby-windows", #includes rubygems
              "ruby-windows-devkit"]

version begin
          ENV['CHEF_GIT_REV'] || "10-stable"
        end

source :git => "git://github.com/opscode/chef"

relative_path "chef"

build do
  #####################################################################
  #
  # nasty nasty nasty hack for setting artifact version
  #
  #####################################################################
  #
  # since omnibus-ruby is not architected to intentionally let the
  # software definitions define the #build_version and
  # #build_iteration of the package artifact, we're going to implement
  # a temporary hack here that lets us do so. this type of use case
  # will become a feature of omnibus-ruby in the future, but in order
  # to get things shipped, we'll hack it up here.
  #
  # <3 Stephen
  #
  #####################################################################
  block do
    project = self.project
    if project.name == "chef-windows"
      git_cmd = "git describe --tags"
      src_dir = self.project_dir
      shell = Mixlib::ShellOut.new(git_cmd,
                                   :cwd => src_dir)
      shell.run_command
      shell.error!
      build_version = shell.stdout.chomp

      project.build_version   build_version
      project.build_iteration ENV["CHEF_PACKAGE_ITERATION"].to_i || 1
    end
  end

  # symlink required unix tools
  # we need tar for 'knife cookbook site install' to function correctly
  {"tar.exe" => "bsdtar.exe",
    "libarchive-2.dll" => "libarchive-2.dll",
    "libexpat-1.dll" => "libexpat-1.dll",
    "liblzma-1.dll" => "liblzma-1.dll",
    "libbz2-2.dll" => "libbz2-2.dll",
    "libz-1.dll" => "libz-1.dll"
  }.each do |target, to|
    command "mklink C:\\opscode\\chef\\bin\\#{target} C:\\opscode\\chef\\embedded\\mingw\\bin\\#{to}"
  end

  gem "install ohai --no-rdoc --no-ri -n C:\\opscode\\chef\\bin"
  gem "install chef --no-rdoc --no-ri -n C:\\opscode\\chef\\bin"

  # gems with precompiled binaries
  gem ["install",
       "ffi win32-api win32-service",
       "--no-rdoc --no-ri"].join(" ")

  # the rest
  gem ["install",
       "rdp-ruby-wmi windows-api windows-pr win32-dir win32-event win32-mutex win32-process",
       "--no-rdoc --no-ri"].join(" ")

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
    %w{chef ohai}.each do |gem|
      gem_file = Dir["C:/opscode/chef/embedded/**/cache/#{gem}*.gem"].first
      gem_executables << Gem::Format.from_file_by_path(gem_file).spec.executables
    end

    puts '*' * 50
    gem_executables.flatten.each do |bin|
      puts "templating #{bin}"
      @bin = bin
      File.open("C:\\opscode\\chef\\bin\\#{@bin}.bat", "w") do |f|
        f.puts batch_template.result(binding)
      end
    end
    puts '*' * 50
  end
end
