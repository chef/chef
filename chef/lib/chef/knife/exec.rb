#--
# Author:: Daniel DeLeo (<dan@opscode.com)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/knife'

class Chef::Knife::Exec < Chef::Knife

  banner "knife exec [SCRIPT] (options)"

  option :exec,
    :short => "-E CODE",
    :long => "--exec CODE",
    :description => "a string of Chef code to execute"

  option :script_path,
    :short => "-p PATH:PATH",
    :long => "--script-path PATH:PATH",
    :description => "A colon-separated path to look for scripts in",
    :proc => lambda { |o| o.split(":") }

  deps do
    require 'chef/shell/ext'
  end

  def run
    config[:script_path] ||= Array(Chef::Config[:script_path])

    # Default script paths are chef-repo/.chef/scripts and ~/.chef/scripts
    config[:script_path] << File.join(Chef::Knife.chef_config_dir, 'scripts') if Chef::Knife.chef_config_dir
    config[:script_path] << File.join(ENV['HOME'], '.chef', 'scripts') if ENV['HOME']

    scripts = Array(name_args)
    context = Object.new
    Shell::Extensions.extend_context_object(context)
    if config[:exec]
      context.instance_eval(config[:exec], "-E Argument", 0)
    elsif !scripts.empty?
      scripts.each do |script|
        file = find_script(script)
        context.instance_eval(IO.read(file), file, 0)
      end
    else
      script = STDIN.read
      context.instance_eval(script, "STDIN", 0)
    end
  end

  def find_script(x)
    # Try to find a script. First try expanding the path given.
    script = File.expand_path(x)
    return script if File.exists?(script)

    # Failing that, try searching the script path. If we can't find
    # anything, fail gracefully.
    Chef::Log.debug("Searching script_path: #{config[:script_path].inspect}")

    config[:script_path].each do |path|
      path = File.expand_path(path)
      test = File.join(path, x)
      Chef::Log.debug("Testing: #{test}")
      if File.exists?(test)
        script = test
        Chef::Log.debug("Found: #{test}")
        return script
      end
    end
    ui.error("\"#{x}\" not found in current directory or script_path, giving up.")
    exit(1)
  end

end
