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

require "singleton"
require "pp"
require "etc"

module Shef
  
  # Set the irb_conf object to something other than IRB.conf
  # usful for testing.
  def self.irb_conf=(conf_hash)
    @irb_conf = conf_hash
  end
  
  def self.irb_conf
    @irb_conf || IRB.conf
  end
  
  def self.configure_irb
    irb_conf[:HISTORY_FILE] = "~/.shef_history"
    irb_conf[:SAVE_HISTORY] = 1000
    
    irb_conf[:IRB_RC] = lambda do |conf|
      m = conf.main
      leader =  case m
                when Chef::Recipe
                  ":recipe"
                when Chef::Node
                  ":attributes"
                else
                  ""
                end

      def m.help
        shef_help
      end

      conf.prompt_c       = "chef#{leader} > "
      conf.return_format  = " => %s \n"
      conf.prompt_i       = "chef#{leader} > "
      conf.prompt_n       = "chef#{leader} ?> "
      conf.prompt_s       = "chef#{leader}%l> "
    end
  end
  
  def self.client
    ShefClient.instance.reset! unless ShefClient.instance.node_built?
    ShefClient.instance
  end
  
  class ShefClient < Hash
    include Singleton
    
    def initialize
      @node_built = false
    end
    
    def node_built?
      !!@node_built
    end
    
    def reset!
      loading = true
      dots = Thread.new do
        print "Loading"
        while loading
          print "."
          sleep 0.5
        end
        print "done.\n\n"
      end

      self[:client] = Chef::Client.new
      self[:client].determine_node_name
      self[:client].build_node(self[:client].node_name, true)
      
      node = self[:node] = self[:client].node
      def node.inspect
        "<Chef::Node:0x#{self.object_id.to_s(16)} @name=\"#{self.name}\">"
      end
      
      self[:recipe] = Chef::Recipe.new(nil, nil, self[:node])
      @node_built = true
      loading = false
      dots.join
    end
 
  end
  
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
        banner << "".ljust(79, "=") + ")"
        banner << "| " + "Command".ljust(20) + "| " + "Description"
        banner << "".ljust(79, "=") + ")"
        self.class.all_help_descriptions.each do |cmd, description|
          banner << "| " + cmd.ljust(20) + "| " + description
        end
        banner << "".ljust(80, "=")
        banner << "\n"
        banner.join("\n")
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

        def method_added(mname)
          if @desc
            help_descriptions << [mname.to_s, @desc.to_s]
            @desc = nil
          end
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