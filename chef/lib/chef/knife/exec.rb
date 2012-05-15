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
    require 'chef/shef/ext'
  end

  def run
    config[:script_path] ||= Chef::Config[:script_path]

    scripts = Array(name_args)
    context = Object.new
    Shef::Extensions.extend_context_object(context)
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
    # Failing that, try searching the script path. If we can't find
    # anything, just return the expanded path of what we were given.

    script = File.expand_path(x)
    unless File.exists?(script)
      Chef::Log.debug("Searching script_path: #{config[:script_path].inspect}")
      config[:script_path].each do |path|
        test = File.join(path, x)
        Chef::Log.debug("Testing: #{test}")
        if File.exists?(test)
          script = test
          Chef::Log.debug("Found: #{test}")
          break
        end
      end
    end
    return script
  end
 
end
