#
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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
end

dependency "rubygems"


#/opt/chefdk/embedded/bin/ruby -e 'puts Gem.dir'
# => /opt/chefdk/embedded/lib/ruby/gems/2.1.0
#
# /opt/chefdk/embedded/bin/ruby -rrbconfig -e "puts RbConfig::CONFIG['sitelibdir']"
# => /opt/chefdk/embedded/lib/ruby/site_ruby/2.1.0

# result should be /opt/chefdk/embedded/lib/ruby/site_ruby/2.1.0/rubygems/defaults/operating_system.rb


build do

  block do
    source_customization_file = File.join(project.files_path, "rubygems_customization", "operating_system.rb")
    embedded_ruby_site_dir = ""
    Bundler.with_clean_env do
      embedded_ruby_site_dir = %x{/opt/chefdk/embedded/bin/ruby -rrbconfig -e "puts RbConfig::CONFIG['sitelibdir']"}.strip
    end

    raise "could not determine embedded ruby's site dir" if embedded_ruby_site_dir.empty?

    destination_dir = File.join(embedded_ruby_site_dir, 'rubygems', 'defaults')
    destination = File.join(destination_dir, "operating_system.rb")

    FileUtils.mkdir_p destination_dir
    command "cp #{source_customization_file} #{destination}"
  end
end

