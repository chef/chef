#--
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2009-2016, Daniel DeLeo
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

require "tempfile" unless defined?(Tempfile)
require_relative "../recipe"
require "fileutils" unless defined?(FileUtils)
require_relative "../dsl/platform_introspection"
require_relative "../version"
require_relative "shell_session"
require_relative "model_wrapper"
require_relative "../server_api"
require_relative "../json_compat"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

module Shell
  module Extensions

    Help = Struct.new(:cmd, :desc, :explanation)

    # Extensions to be included in every 'main' object in chef-shell.
    # These objects are extended with this module.
    module ObjectCoreExtensions

      def ensure_session_select_defined
        # irb breaks if you prematurely define IRB::JobManager
        # so these methods need to be defined at the latest possible time.
        unless jobs.respond_to?(:select_session_by_context)
          def jobs.select_session_by_context(&block) # rubocop:disable Lint/NestedMethodDefinition
            @jobs.select { |job| block.call(job[1].context.main) }
          end
        end

        unless jobs.respond_to?(:session_select)
          def jobs.select_shell_session(target_context) # rubocop:disable Lint/NestedMethodDefinition
            session = if target_context.is_a?(Class)
                        select_session_by_context { |main| main.is_a?(target_context) }
                      else
                        select_session_by_context { |main| main.equal?(target_context) }
                      end
            Array(session.first)[1]
          end
        end
      end

      def find_or_create_session_for(context_obj)
        ensure_session_select_defined
        if subsession = jobs.select_shell_session(context_obj)
          jobs.switch(subsession)
        else
          irb(context_obj) # rubocop: disable Lint/Debugger
        end
      end

      def help_banner
        banner = []
        banner << ""
        banner << "#{ChefUtils::Dist::Infra::SHELL} Help"
        banner << "".ljust(80, "=")
        banner << "| " + "Command".ljust(25) + "| " + "Description"
        banner << "".ljust(80, "=")

        all_help_descriptions.each do |help_text|
          banner << "| " + help_text.cmd.ljust(25) + "| " + help_text.desc
        end
        banner << "".ljust(80, "=")
        banner << "\n"
        banner << "Use help(:command) to get detailed help with individual commands"
        banner << "\n"
        banner.join("\n")
      end

      def explain_command(method_name)
        help = all_help_descriptions.find { |h| h.cmd.to_s == method_name.to_s }
        if help
          puts ""
          puts "Command: #{method_name}"
          puts "".ljust(80, "=")
          puts help.explanation || help.desc
          puts "".ljust(80, "=")
          puts ""
        else
          puts ""
          puts "command #{method_name} not found or no help available"
          puts ""
        end
      end

      # helpfully returns +:on+ so we can have sugary syntax like `tracing on'
      def on
        :on
      end

      # returns +:off+ so you can just do `tracing off'
      def off
        :off
      end

      def help_descriptions
        @help_descriptions ||= []
      end

      def all_help_descriptions
        help_descriptions
      end

      def desc(help_text)
        @desc = help_text
      end

      def explain(explain_text)
        @explain = explain_text
      end

      def subcommands(subcommand_help = {})
        @subcommand_help = subcommand_help
      end

      def singleton_method_added(mname)
        if @desc
          help_descriptions << Help.new(mname.to_s, @desc.to_s, @explain)
          @desc, @explain = nil, nil
        end
        if @subcommand_help
          @subcommand_help.each do |subcommand, text|
            help_descriptions << Help.new("#{mname}.#{subcommand}", text.to_s, nil)
          end
        end
        @subcommand_help = {}
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
        to_s.on_off_to_bool
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

    # Methods that have associated help text need to be dynamically added
    # to the main irb objects, so we define them in a proc and later
    # instance_eval the proc in the object.
    ObjectUIExtensions = Proc.new do
      extend Shell::Extensions::ObjectCoreExtensions

      desc "prints this help message"
      explain(<<~E)
        ## SUMMARY ##
          When called with no argument, +help+ prints a table of all
          #{ChefUtils::Dist::Infra::SHELL} commands. When called with an argument COMMAND, +help+
          prints a detailed explanation of the command if available, or the
          description if no explanation is available.
      E
      def help(command = nil)
        if command
          explain_command(command)
        else
          puts help_banner
        end
        :help
      end
      alias :halp :help

      desc "prints information about #{ChefUtils::Dist::Infra::PRODUCT}"
      def version
        puts "Welcome to the #{ChefUtils::Dist::Infra::SHELL} #{::Chef::VERSION}\n" +
          "For usage see https://docs.chef.io/chef_shell/"
        :ucanhaz_automation
      end
      alias :shell :version

      desc "switch to recipe mode"
      def recipe_mode
        find_or_create_session_for Shell.session.recipe
        :recipe
      end

      desc "switch to attributes mode"
      def attributes_mode
        find_or_create_session_for Shell.session.node
        :attributes
      end

      desc "run #{ChefUtils::Dist::Infra::PRODUCT} using the current recipe"
      def run_chef
        Chef::Log.level = :debug
        session = Shell.session
        runrun = Chef::Runner.new(session.run_context).converge
        Chef::Log.level = :info
        runrun
      end

      desc "returns an object to control a paused #{ChefUtils::Dist::Infra::PRODUCT} run"
      subcommands resume: "resume the #{ChefUtils::Dist::Infra::PRODUCT} run",
                  step: "run only the next resource",
                  skip_back: "move back in the run list",
                  skip_forward: "move forward in the run list"
      def chef_run
        Shell.session.resource_collection.iterator
      end

      desc "resets the current recipe"
      def reset
        Shell.session.reset!
      end

      desc "assume the identity of another node."
      def become_node(node_name)
        Shell::DoppelGangerSession.instance.assume_identity(node_name)
        :doppelganger
      end
      alias :doppelganger :become_node

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

    MainContextExtensions = Proc.new do
      desc "returns the current node (i.e., this host)"
      def node
        Shell.session.node
      end

      desc "pretty print the node's attributes"
      def ohai(key = nil)
        pp(key ? node.attribute[key] : node.attribute)
      end
    end

    RESTApiExtensions = Proc.new do
      desc "edit an object in your EDITOR"
      explain(<<~E)
        ## SUMMARY ##
          +edit(object)+ allows you to edit any object that can be converted to JSON.
          When finished editing, this method will return the edited object:

              new_node = edit(existing_node)

        ## EDITOR SELECTION ##
          #{ChefUtils::Dist::Infra::SHELL} looks for an editor using the following logic
          1. Looks for an EDITOR set by Shell.editor = "EDITOR"
          2. Looks for an EDITOR configured in your #{ChefUtils::Dist::Infra::SHELL} config file
          3. Uses the value of the EDITOR environment variable
      E
      def edit(object)
        unless Shell.editor
          puts "Please set your editor with Shell.editor = \"vim|emacs|mate|ed\""
          return :failburger
        end

        filename = "#{ChefUtils::Dist::Infra::SHELL}-edit-#{object.class.name}-"
        if object.respond_to?(:name)
          filename += object.name
        elsif object.respond_to?(:id)
          filename += object.id
        end

        edited_data = Tempfile.open([filename, ".js"]) do |tempfile|
          tempfile.sync = true
          tempfile.puts Chef::JSONCompat.to_json(object)
          system("#{Shell.editor} #{tempfile.path}")
          tempfile.rewind
          tempfile.read
        end

        Chef::JSONCompat.from_json(edited_data)
      end

      desc "Find and edit API clients"
      explain(<<~E)
        ## SUMMARY ##
          +clients+ allows you to query you chef server for information about your api
          clients.

        ## LIST ALL CLIENTS ##
          To see all clients on the system, use

              clients.all #=> [<Chef::ApiClient...>, ...]

          If the output from all is too verbose, or you're only interested in a specific
          value from each of the objects, you can give a code block to +all+:

              clients.all { |client| client.name } #=> [CLIENT1_NAME, CLIENT2_NAME, ...]

        ## SHOW ONE CLIENT ##
          To see a specific client, use

              clients.show(CLIENT_NAME)

        ## SEARCH FOR CLIENTS ##
          You can also search for clients using +find+ or +search+. You can use the
          familiar string search syntax:

              clients.search("KEY:VALUE")

          Just as the +all+ subcommand, the +search+ subcommand can use a code block to
          filter or transform the information returned from the search:

              clients.search("KEY:VALUE") { |c| c.name }

          You can also use a Hash based syntax, multiple search conditions will be
          joined with AND.

              clients.find :KEY => :VALUE, :KEY2 => :VALUE2, ...

        ## BULK-EDIT CLIENTS ##
                            **BE CAREFUL, THIS IS DESTRUCTIVE**
          You can bulk edit API Clients using the +transform+ subcommand, which requires
          a code block. Each client will be saved after the code block is run. If the
          code block returns +nil+ or +false+, that client will be skipped:

              clients.transform("*:*") do |client|
                if client.name =~ /borat/i
                  client.admin(false)
                  true
                else
                  nil
                end
              end

          This will strip the admin privileges from any client named after borat.
      E
      subcommands all: "list all api clients",
                  show: "load an api client by name",
                  search: "search for API clients",
                  transform: "edit all api clients via a code block and save them"
      def clients
        @clients ||= Shell::ModelWrapper.new(Chef::ApiClient, :client)
      end

      desc "Find and edit cookbooks"
      subcommands all: "list all cookbooks",
                  show: "load a cookbook by name",
                  transform: "edit all cookbooks via a code block and save them"
      def cookbooks
        @cookbooks ||= Shell::ModelWrapper.new(Chef::CookbookVersion)
      end

      desc "Find and edit nodes via the API"
      explain(<<~E)
        ## SUMMARY ##
          +nodes+ Allows you to query your chef server for information about your nodes.

        ## LIST ALL NODES ##
          You can list all nodes using +all+ or +list+

              nodes.all #=> [<Chef::Node...>, <Chef::Node...>, ...]

          To limit the information returned for each node, pass a code block to the +all+
          subcommand:

              nodes.all { |node| node.name } #=> [NODE1_NAME, NODE2_NAME, ...]

        ## SHOW ONE NODE ##
          You can show the data for a single node using the +show+ subcommand:

              nodes.show("NODE_NAME") => <Chef::Node @name="NODE_NAME" ...>

        ## SEARCH FOR NODES ##
          You can search for nodes using the +search+ or +find+ subcommands:

              nodes.find(:name => "app*") #=> [<Chef::Node @name="app1.example.com" ...>, ...]

          Similarly to +all+, you can pass a code block to limit or transform the
          information returned:

              nodes.find(:name => "app#") { |node| node.ec2 }

        ## BULK EDIT NODES ##
                      **BE CAREFUL, THIS OPERATION IS DESTRUCTIVE**

          Bulk edit nodes by passing a code block to the +transform+ or +bulk_edit+
          subcommand. The block will be applied to each matching node, and then the node
          will be saved. If the block returns +nil+ or +false+, that node will be
          skipped.

              nodes.transform do |node|
                if node.fqdn =~ /.*\\.preprod\\.example\\.com/
                  node.set[:environment] = "preprod"
                end
              end

          This will assign the attribute to every node with a FQDN matching the regex.
      E
      subcommands all: "list all nodes",
                  show: "load a node by name",
                  search: "search for nodes",
                  transform: "edit all nodes via a code block and save them"
      def nodes
        @nodes ||= Shell::ModelWrapper.new(Chef::Node)
      end

      desc "Find and edit roles via the API"
      explain(<<~E)
        ## SUMMARY ##
          +roles+ allows you to query and edit roles on your Chef server.

        ## SUBCOMMANDS ##
          * all       (list)
          * show      (load)
          * search    (find)
          * transform (bulk_edit)

        ## SEE ALSO ##
          See the help for +nodes+ for more information about the subcommands.
      E
      subcommands all: "list all roles",
                  show: "load a role by name",
                  search: "search for roles",
                  transform: "edit all roles via a code block and save them"
      def roles
        @roles ||= Shell::ModelWrapper.new(Chef::Role)
      end

      desc "Find and edit +databag_name+ via the api"
      explain(<<~E)
        ## SUMMARY ##
          +databags(DATABAG_NAME)+ allows you to query and edit data bag items on your
          Chef server. Unlike other commands for working with data on the server,
          +databags+ requires the databag name as an argument, for example:
            databags(:users).all

        ## SUBCOMMANDS ##
          * all       (list)
          * show      (load)
          * search    (find)
          * transform (bulk_edit)

        ## SEE ALSO ##
          See the help for +nodes+ for more information about the subcommands.

      E
      subcommands all: "list all items in the data bag",
                  show: "load a data bag item by id",
                  search: "search for items in the data bag",
                  transform: "edit all items via a code block and save them"
      def databags(databag_name)
        @named_databags_wrappers ||= {}
        @named_databags_wrappers[databag_name] ||= Shell::NamedDataBagWrapper.new(databag_name)
      end

      desc "Find and edit environments via the API"
      explain(<<~E)
        ## SUMMARY ##
          +environments+ allows you to query and edit environments on your Chef server.

        ## SUBCOMMANDS ##
          * all       (list)
          * show      (load)
          * search    (find)
          * transform (bulk_edit)

        ## SEE ALSO ##
          See the help for +nodes+ for more information about the subcommands.
      E
      subcommands all: "list all environments",
                  show: "load an environment by name",
                  search: "search for environments",
                  transform: "edit all environments via a code block and save them"
      def environments
        @environments ||= Shell::ModelWrapper.new(Chef::Environment)
      end

      desc "A REST Client configured to authenticate with the API"
      def api
        @rest = Chef::ServerAPI.new(Chef::Config[:chef_server_url])
      end

    end

    RecipeUIExtensions = Proc.new do
      alias :original_resources :resources

      desc "list all the resources on the current recipe"
      def resources(*args)
        if args.empty?
          pp run_context.resource_collection.keys
        else
          pp resources = original_resources(*args)
          resources
        end
      end
    end

    def self.extend_context_object(obj)
      obj.instance_eval(&ObjectUIExtensions)
      obj.instance_eval(&MainContextExtensions)
      obj.instance_eval(&RESTApiExtensions)
      obj.extend(FileUtils)
      obj.extend(Chef::DSL::PlatformIntrospection)
      obj.extend(Chef::DSL::DataQuery)
    end

    def self.extend_context_node(node_obj)
      node_obj.instance_eval(&ObjectUIExtensions)
    end

    def self.extend_context_recipe(recipe_obj)
      recipe_obj.instance_eval(&ObjectUIExtensions)
      recipe_obj.instance_eval(&RecipeUIExtensions)
    end

  end
end

class String
  include Shell::Extensions::String
end

class Symbol
  include Shell::Extensions::Symbol
end

class TrueClass
  include Shell::Extensions::TrueClass
end

class FalseClass
  include Shell::Extensions::FalseClass
end
