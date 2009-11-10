# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

class String
  include Shef::Extensions::String
end

class Symbol
  include Shef::Extensions::Symbol
end

class TrueClass
  include Shef::Extensions::TrueClass
end

class FalseClass
  include Shef::Extensions::FalseClass
end

class Object
  extend Shef::Extensions::Object::ClassMethods
  include Shef::Extensions::Object
  
  desc "prints this help message"
  def shef_help(title="Help: Shef")
    #puts Shef::Extensions::Object.help_banner("Shef Help")
    puts help_banner(title)
    :ucanhaz_halp
  end
  alias :halp :shef_help
  
  desc "prints information about chef"
  def chef
    puts  "This is shef, the Chef shell.\n" + 
          " Chef Version: #{::Chef::VERSION}\n" +
          " http://wiki.opscode.com/display/chef/Home"
    :ucanhaz_automation
  end
  alias :version :chef
  alias :shef :chef
  
  desc "switch to recipe mode"
  def recipe
    find_or_create_session_for Shef.client[:recipe]
    :recipe
  end
  
  desc "switch to attributes mode"
  def attributes
    find_or_create_session_for Shef.client[:node]
    :attributes
  end
  
  desc "returns the current node (i.e., this host)"
  def node
    Shef.client[:node]
  end
  
  desc "pretty print the node's attributes"
  def ohai(key=nil)
    pp(key ? node.attribute[key] : node.attribute)
  end
  
  desc "run chef using the current recipe"
  def run_chef
    Chef::Log.level(:debug)
    runrun = Chef::Runner.new(node, Shef.client[:recipe].collection).converge
    Chef::Log.level(:info)
    runrun
  end
  
  desc "resets the current recipe"
  def reset
    Shef.client.reset!
  end
  
  desc "turns printout of the last value returned on or off"
  def echo(on_or_off)
    conf.echo = on_or_off.on_off_to_bool
  end
  
  desc "says if echo is on or off"
  def echo?
    puts "echo is #{conf.echo.to_on_off_str}"
  end
  
  desc "turns on or off tracing of execution. *very verbose*"
  def tracing(on_or_off)
    conf.use_tracer = on_or_off.on_off_to_bool
    tracing?
  end
  alias :trace :tracing
  
  desc "says if tracing is on or off"
  def tracing?
    puts "tracing is #{conf.use_tracer.to_on_off_str}"
  end
  alias :trace? :tracing?
  
end

class Chef
  class Recipe
    
    def shef_help
      super("Help: Shef/Recipe")
    end
    
    alias :original_resources :resources
    
    desc "list all the resources on the current recipe"
    def resources(*args)
      if args.empty?
        pp collection.instance_variable_get(:@resources_by_name).keys
      else
        pp resources = original_resources(*args)
        resources
      end
    end
  end
end