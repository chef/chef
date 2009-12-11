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

module Shef
  module Extensions
    
    # Extensions to be included in object. These are methods that have to be
    # defined on object but are not part of the user interface. Methods that
    # are part of the user interface should have help text defined with the
    # +desc+ macro, and need to be defined directly on Object in ext.rb
    module Object
      
      def ensure_session_select_defined
        # irb breaks if you prematurely define IRB::JobMangager
        # so these methods need to be defined at the latest possible time.
        unless jobs.respond_to?(:select_session_by_context)
          def jobs.select_session_by_context(&block)
            @jobs.select { |job| block.call(job[1].context.main)}
          end
        end

        unless jobs.respond_to?(:session_select)
          def jobs.select_shef_session(target_context)
            session = if target_context.kind_of?(Class)
              select_session_by_context { |main| main.kind_of?(target_context) }
            else
              select_session_by_context { |main| main.equal?(target_context) }
            end
            Array(session.first)[1]
          end
        end
      end

      def find_or_create_session_for(context_obj)
        ensure_session_select_defined
        if subsession = jobs.select_shef_session(context_obj)
          jobs.switch(subsession)
        else
          irb(context_obj)
        end
      end
      
      def help_banner(title=nil)
        banner = []
        banner << ""
        banner << title if title
        banner << "".ljust(80, "=")
        banner << "| " + "Command".ljust(25) + "| " + "Description"
        banner << "".ljust(80, "=")
        self.class.all_help_descriptions.each do |cmd, description|
          banner << "| " + cmd.ljust(25) + "| " + description
        end
        banner << "".ljust(80, "=")
        banner << "\n"
        banner.join("\n")
      end
      
      # helpfully returns +:on+ so we can have sugary syntax like `tracing on'
      def on
        :on
      end
      
      # returns +:off+ so you can just do `tracing off'
      def off
        :off
      end
      
      module ClassMethods

        def help_descriptions
          @help_descriptions ||= []
        end
        
        def all_help_descriptions
          if sc = superclass
            help_descriptions + sc.help_descriptions
          else
            help_descriptions
          end
        end

        def desc(help_text)
          @desc = help_text
        end
        
        def subcommands(subcommand_help={})
          @subcommand_help = subcommand_help
        end

        def method_added(mname)
          if @desc
            help_descriptions << [mname.to_s, @desc.to_s]
            @desc = nil
          end
          if @subcommand_help
            @subcommand_help.each do |subcommand, text|
              help_descriptions << ["#{mname}.#{subcommand}", text.to_s]
            end
          end
          @subcommand_help = {}
        end

      end
      
    end
    
    module String
      def on_off_to_bool
        case self
        when "on"
          true
        when "off"
          false
        else
          self
        end
      end
    end
    
    module Symbol
      def on_off_to_bool
        self.to_s.on_off_to_bool
      end
    end
    
    module TrueClass
      def to_on_off_str
        "on"
      end
      
      def on_off_to_bool
        self
      end
    end
    
    module FalseClass
      def to_on_off_str
        "off"
      end
      
      def on_off_to_bool
        self
      end
    end
    
  end
end

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
  include FileUtils
  
  desc "prints this help message"
  def shef_help(title="Help: Shef")
    #puts Shef::Extensions::Object.help_banner("Shef Help")
    puts help_banner(title)
    :ucanhaz_halp
  end
  alias :halp :shef_help
  
  desc "prints information about chef"
  def version
    puts  "This is shef, the Chef shell.\n" + 
          " Chef Version: #{::Chef::VERSION}\n" +
          " http://www.opscode.com/chef\n" +
          " http://wiki.opscode.com/display/chef/Home"
    :ucanhaz_automation
  end
  alias :shef :version
  
  desc "switch to recipe mode"
  def recipe
    find_or_create_session_for Shef.session.recipe
    :recipe
  end
  
  desc "switch to attributes mode"
  def attributes
    find_or_create_session_for Shef.session.node
    :attributes
  end
  
  desc "returns the current node (i.e., this host)"
  def node
    Shef.session.node
  end
  
  desc "pretty print the node's attributes"
  def ohai(key=nil)
    pp(key ? node.attribute[key] : node.attribute)
  end
  
  desc "run chef using the current recipe"
  def run_chef
    Chef::Log.level = :debug
    session = Shef.session
    session.rebuild_collection
    runrun = Chef::Runner.new(node, session.collection, session.definitions, session.cookbook_loader).converge
    Chef::Log.level = :info
    runrun
  end
  
  desc "returns an object to control a paused chef run"
  subcommands :resume       => "resume the chef run",
              :step         => "run only the next resource",
              :skip_back    => "move back in the run list",
              :skip_forward => "move forward in the run list"
  def chef_run
    Shef.session.collection.iterator
  end
  
  desc "resets the current recipe"
  def reset
    Shef.session.reset!
  end
  
  desc "turns printout of return values on or off"
  def echo(on_or_off)
    conf.echo = on_or_off.on_off_to_bool
  end
  
  desc "says if echo is on or off"
  def echo?
    puts "echo is #{conf.echo.to_on_off_str}"
  end
  
  desc "turns on or off tracing of execution. *verbose*"
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
  
  desc "simple ls style command"
  def ls(directory)
    Dir.entries(directory)
  end
  
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
