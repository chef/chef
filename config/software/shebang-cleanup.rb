#
# Copyright 2012-2014 Chef Software, Inc.
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

#
# Use this software definition to fix the shebangs of binaries under embedded/bin
# to point to the embedded ruby.
#

name "shebang-cleanup"

default_version "0.0.2"

build do
  if windows?
    block "Update batch files to point at embedded ruby" do
      load_gemspec = if Gem::VERSION >= '2'
                       require 'rubygems/package'
                       Gem::Package.method(:new)
                     else
                       require 'rubygems/format'
                       Gem::Format.method(:from_file_by_path)
                     end
      Dir["#{install_dir.gsub(/\\/, '/')}/embedded/lib/ruby/gems/**/cache/*.gem"].each do |gem_file|
        load_gemspec.call(gem_file).spec.executables.each do |bin|
          if File.exists?("#{install_dir}/bin/#{bin}")
            File.open("#{install_dir}/bin/#{bin}.bat", "w") do |f|
              f.puts <<-EOF
@ECHO OFF
"%~dp0\\..\\embedded\\bin\\ruby.exe" "%~dpn0" %*
              EOF
            end
          end
          if File.exists?("#{install_dir}/embedded/bin/#{bin}")
            File.open("#{install_dir}/embedded/bin/#{bin}.bat", "w") do |f|
              f.puts <<-EOF
@ECHO OFF
"%~dp0\\ruby.exe" "%~dpn0" %*
              EOF
            end
          end
        end
      end

      # Fix gem.bat
      File.open("#{install_dir}/embedded/bin/gem.bat", "w") do |f|
        f.puts <<-EOF
@ECHO OFF
"%~dp0\\ruby.exe" "%~dpn0" %*
        EOF
      end
    end
  else
    block "Update shebangs to point to embedded Ruby" do
      # Fix the shebang for binaries with shebangs that have:
      # #!/usr/bin/env ruby
      Dir.glob("#{install_dir}/embedded/bin/*") do |bin_file|
        update_shebang = false
        rest_of_the_file = ""

        File.open(bin_file) do |f|
          shebang = f.readline
          if shebang.start_with?("#!") &&
              shebang.include?("ruby") &&
              !shebang.include?("#{install_dir}/embedded/bin/ruby")
            rest_of_the_file = f.read
            update_shebang = true
          end
        end

        if update_shebang
          File.open(bin_file, "w+") do |f|
            f.puts("#!#{install_dir}/embedded/bin/ruby")
            f.puts(rest_of_the_file)
          end
        end
      end
    end
  end
end
