#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

name "rubygems-customization"

default_version "0.1.0"

if platform == 'windows'
  dependency "ruby-windows"
else
  dependency "ruby"
  dependency "rubygems"
end



#/opt/chefdk/embedded/bin/ruby -e 'puts Gem.dir'
# => /opt/chefdk/embedded/lib/ruby/gems/2.1.0
#
# /opt/chefdk/embedded/bin/ruby -rrbconfig -e "puts RbConfig::CONFIG['sitelibdir']"
# => /opt/chefdk/embedded/lib/ruby/site_ruby/2.1.0

# result should be /opt/chefdk/embedded/lib/ruby/site_ruby/2.1.0/rubygems/defaults/operating_system.rb


build do
  sitelibdir_cmd = %Q{#{install_dir}/embedded/bin/ruby -rrbconfig -e "puts RbConfig::CONFIG['sitelibdir']"}

  # TODO: use +windows_safe_path+
  sitelibdir_cmd.gsub!('/', '\\') if platform == "windows"

  block do
    source_customization_file = if platform == 'windows'
      File.join(project.files_path, "rubygems_customization", "windows", "operating_system.rb")
    else
      File.join(project.files_path, "rubygems_customization", "default", "operating_system.rb")
    end
    embedded_ruby_site_dir = ""
    Bundler.with_clean_env do
      embedded_ruby_site_dir = %x{#{sitelibdir_cmd}}.strip
    end

    raise "could not determine embedded ruby's site dir" if embedded_ruby_site_dir.empty?

    if sysdrive = ENV['SYSTEMDRIVE']
      match_drive = Regexp.new(Regexp.escape(sysdrive), Regexp::IGNORECASE)
      embedded_ruby_site_dir.sub!(match_drive, '')
    end

    destination_dir = File.join(embedded_ruby_site_dir, 'rubygems', 'defaults')
    destination = File.join(destination_dir, "operating_system.rb")

    FileUtils.mkdir_p destination_dir
    FileUtils.cp source_customization_file, destination
  end
end
