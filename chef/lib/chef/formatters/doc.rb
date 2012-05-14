require 'chef/formatters/base'

class Chef
  module Formatters

    class CompileErrorInspector

      attr_reader :path
      attr_reader :exception

      def initialize(path, exception)
        @path, @exception = path, exception
      end

      def context
        context_lines = ""
        Range.new(display_lower_bound, display_upper_bound).each do |i|
          line_nr = (i + 1).to_s.rjust(3)
          indicator = (i + 1) == culprit_line ? ">> " : ":  "
          context_lines << "#{line_nr}#{indicator}#{file_lines[i]}"
        end
        context_lines
      end

      def display_lower_bound
        lower = (culprit_line - 8)
        lower = 0 if lower < 0
        lower
      end

      def display_upper_bound
        upper = (culprit_line + 8)
        upper = file_lines.size if upper > file_lines.size
        upper
      end

      def file_lines
        @file_lines ||= IO.readlines(path)
      end

      def culprit_backtrace_entry
        @culprit_backtrace_entry ||= exception.backtrace.find {|line| line =~ /^#{@path}/ }
      end

      def culprit_line
        @culprit_line ||= culprit_backtrace_entry[/^#{@path}:([\d]+)/,1].to_i
      end

      def filtered_bt
        exception.backtrace.select {|l| l =~ /^#{Chef::Config.file_cache_path}/ }
      end

    end

    #--
    # TODO: not sold on the name, but the output is similar to what rspec calls
    # "specdoc"
    class Doc < Formatters::Base

      cli_name(:doc)

      def initialize(out, err)
        super

        @updated_resources = []
        @updates_by_resource = Hash.new {|h, k| h[k] = []}
      end

      def run_start(version)
        puts "Starting Chef Client, version #{version}"
      end

      def run_completed
        puts "Chef Client finished, #{@updated_resources.size} resources updated"
      end

      # Called right after ohai runs.
      def ohai_completed(node)
      end

      # Already have a client key, assuming this node has registered.
      def skipping_registration(node_name, config)
      end

      # About to attempt to register as +node_name+
      def registration_start(node_name, config)
      end

      def registration_completed
      end

      # Failed to register this client with the server.
      def registration_failed(node_name, exception, config)
      end

      def node_load_start(node_name, config)
      end

      # Failed to load node data from the server
      def node_load_failed(node_name, exception, config)
      end

      # Default and override attrs from roles have been computed, but not yet applied.
      # Normal attrs from JSON have been added to the node.
      def node_load_completed(node, expanded_run_list, config)
      end

      # Called before the cookbook collection is fetched from the server.
      def cookbook_resolution_start(expanded_run_list)
        puts "resolving cookbooks for run list: #{expanded_run_list.inspect}"
      end

      # Called when there is an error getting the cookbook collection from the
      # server.
      def cookbook_resolution_failed(expanded_run_list, exception)
      end

      # Called when the cookbook collection is returned from the server.
      def cookbook_resolution_complete(cookbook_collection)
      end

      # Called before unneeded cookbooks are removed
      def cookbook_clean_start
      end

      # Called after the file at +path+ is removed. It may be removed if the
      # cookbook containing it was removed from the run list, or if the file was
      # removed from the cookbook.
      def removed_cookbook_file(path)
      end

      # Called when cookbook cleaning is finished.
      def cookbook_clean_complete
      end

      # Called before cookbook sync starts
      def cookbook_sync_start(cookbook_count)
        puts "Synchronizing Cookbooks:"
      end

      # Called when cookbook +cookbook_name+ has been sync'd
      def synchronized_cookbook(cookbook_name)
        puts "  - #{cookbook_name}"
      end

      # Called when an individual file in a cookbook has been updated
      def updated_cookbook_file(cookbook_name, path)
      end

      # Called after all cookbooks have been sync'd.
      def cookbook_sync_complete
      end

      # Called when cookbook loading starts.
      def library_load_start(file_count)
        puts "Compiling Cookbooks..."
      end

      # Called after a file in a cookbook is loaded.
      def file_loaded(path)
      end

      def file_load_failed(path, exception)
        wrapped_err = CompileErrorInspector.new(path, exception)
        puts "\n"
        puts "-" * 80
        puts "Error compiling #{path}:"
        puts exception.to_s
        puts "\n"
        puts "Cookbook trace:"
        wrapped_err.filtered_bt.each do |bt_line|
          puts "  #{bt_line}"
        end
        puts "\n"
        puts "Most likely caused here:"
        puts wrapped_err.context
        puts "\n"
        puts "-" * 80
      end

      # Called when recipes have been loaded.
      def recipe_load_complete
      end

      # Called before convergence starts
      def converge_start(run_context)
        puts "Converging #{run_context.resource_collection.all_resources.size} resources"
      end

      # Called when the converge phase is finished.
      def converge_complete
      end

      # Called before action is executed on a resource.
      def resource_action_start(resource, action, notification_type=nil, notifier=nil)
        if resource.cookbook_name && resource.recipe_name
          resource_recipe = "#{resource.cookbook_name}::#{resource.recipe_name}"
        else
          resource_recipe = "<Dynamically Defined Resource>"
        end

        if resource_recipe != @current_recipe
          puts "Recipe: #{resource_recipe}"
          @current_recipe = resource_recipe
        end
        # TODO: info about notifies
        print "  * #{resource} action #{action}"
      end

      # Called when a resource fails, but will retry.
      def resource_failed_retriable(resource, action, retry_count, exception)
      end

      # Called when a resource fails and will not be retried.
      def resource_failed(resource, action, exception)
        puts "\n"
        puts "Error converging #{resource} #{resource.defined_at}"
        puts "\n"
        puts resource.to_text

      end

      # Called when a resource action has been skipped b/c of a conditional
      def resource_skipped(resource, action, conditional)
        # TODO: more info about conditional
        puts " (skipped due to #{conditional.positivity})"
      end

      # Called after #load_current_resource has run.
      def resource_current_state_loaded(resource, action, current_resource)
      end

      # Called when a resource has no converge actions, e.g., it was already correct.
      def resource_up_to_date(resource, action)
        puts " (up to date)"
      end

      ## TODO: callback for assertion failures

      ## TODO: callback for assertion fallback in why run

      # Called when a change has been made to a resource. May be called multiple
      # times per resource, e.g., a file may have its content updated, and then
      # its permissions updated.
      def resource_update_applied(resource, action, update)
        print "\n    - #{update}"
      end

      # Called after a resource has been completely converged.
      def resource_updated(resource, action)
        puts "\n"
      end

    end
  end
end
