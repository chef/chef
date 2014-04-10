class Mash
  def update(other_hash)
    other_hash.each_pair { |key, value| self[key] = value }
    self
  end
end

class Chef

  class Config
    default :trace_attributes, 'none'

    config_attr_writer :trace_attributes do |path|
      if ['none', 'all'].include?(path) then
        path
      elsif path.match(%r{^/(\w+)(/\w+)*$})
        path
      else
        raise Chef::Exceptions::ConfigurationError, "'trace_attributes' setting should be either 'none', 'all', or a path like /foo/bar"
      end
    end
  end

  class Node

    class AttributeTraceEntry
      attr_reader :component
      attr_reader :source_location
      attr_reader :action
      attr_accessor :value
      attr_accessor :path

      def initialize(a_component, an_action = :set, a_source_location = nil, a_path=nil, a_value=nil)
        @component  = a_component
        @action     = an_action 
        @path       = a_path
        @value    = a_value
        @source_location = a_source_location || source_location_heuristic
      end

      def source_location_heuristic

        stack = pretty_callstack
        location = {}

        # If there is a global hint, copy it in.
        if Chef::Node::Attribute.tracer_hint
          location.merge! Chef::Node::Attribute.tracer_hint
        end

        if false
          # Just for code layout

        elsif slh_looks_like_cookbook(stack)
          location = interpret_cookbook_match(stack, location)

        elsif slh_looks_like_ohai_bulk_load(stack)
          location[:mechanism] = :ohai
          location[:explanation] = 'storing discovered data from ohai plugins'

        elsif slh_looks_like_ohai_platform_detection(stack)
          location[:mechanism] = :ohai
          location[:explanation] = 'storing platform detection information from ohai'

        elsif slh_looks_like_role_load(stack)
          # Expecting role_name to be set by RunListExpansion in the tracer_hint
          location[:mechanism] = :role
          location[:explanation] = 'Applying attributes from loading a role'

        elsif slh_looks_like_role_expansion_merge(stack)
          # No role-specific info can remain at this point; we're just merging in the completed expansion of all roles.
          location[:mechanism] = :'chef-client'
          location[:explanation] = "Having merged all role attributes into an 'expansion', the chef run is now importing the expansion into the node object."

        elsif slh_looks_like_recipe_expansion_merge(stack)
          location[:mechanism] = :'chef-client'
          location[:explanation] = "Having expanded the runlist from the roles, the chef client is now setting the final role list and recipe list on the node object."
                    
        elsif slh_looks_like_environment_load(stack)
          # Expecting environment_name to be set by node.apply_expansion_attributes in the tracer_hint
          location[:mechanism] = :environment
          location[:explanation] = 'Applying attributes from loading an environment'
          location[:server] = Chef::Config.chef_server_url

        elsif slh_looks_like_attribute_reset(stack)
          location[:mechanism] = :'chef-client'
          location[:explanation] = 'client resetting default and override attributes obtained from chef server prior to run'

        elsif slh_looks_like_node_construction_from_http(stack)
          location[:mechanism] = :'node-record'
          location[:explanation] = 'setting attributes from the node record obtained from the server'
          location[:node_name] = Chef::Config.node_name
          location[:server] = Chef::Config.chef_server_url

        elsif slh_looks_like_cli_load(stack)
          # This one needs to happen fairly late, because the matcher 
          # is rather vague; give more specific things a chance to match first.
          location[:mechanism] = :'command-line-json'
          location[:explanation] = 'attributes loaded from command-line using -j json'

          # MixLib::CLI now preserves ARGV.  In other news, it silently ignores all but the first -j .
          dash_j = ARGV.find_index { |arg| ['-j', '--json'].include?(arg) }
          if dash_j
            location[:json_file] = ARGV[dash_j + 1]
          end

        else
          location[:mechanism] = :unknown
          location[:stack] = stack[3,12]
        end

        return location
      end

      private
      def interpret_cookbook_match(stack, location)
        cookbook_frame_indices = []
        stack.each_with_index { |f,i| if f[:cookbook] then cookbook_frame_indices << i end }
        
        
        nearest_frame = stack[cookbook_frame_indices[0]]
        
        if nearest_frame[:method] == 'from_file' && nearest_frame[:cookbook_part] == 'attributes'

          # Check for a reload situation
          if cookbook_frame_indices[1]
            reloading_frame = stack[cookbook_frame_indices[1]]
            if reloading_frame[:cookbook_part] == "recipes"
              location[:mechanism] = :'cookbook-attributes-reload'
              location[:explanation] = "An attribute was reloaded from a cookbook attribute file by a recipe"
              location[:reloaded_by_line] = reloading_frame[:line].to_i
              location[:reloaded_by_file] = reloading_frame[:cookbook] + '/'  + reloading_frame[:path_within_cookbook]              
            end
            # TODO - handle include_attributes?
          else
            # Typical case
            location[:mechanism] = :'cookbook-attributes'
            location[:explanation] = "An attribute was touched by a cookbook's attribute file"
          end

        elsif nearest_frame[:method] == 'from_file' && nearest_frame[:cookbook_part] == 'recipes'
          location[:mechanism] = :'cookbook-recipe-compile-time'
          location[:explanation] = "An attribute was set in a cookbook recipe, outside of a resource."
        elsif nearest_frame[:method] == "block (2 levels) in from_file" && nearest_frame[:cookbook_part] == 'recipes'
          location[:mechanism] = :'cookbook-recipe-converge-time'
          location[:explanation] = "An attribute was set in a cookbook recipe during convergence time (while a resource was being executed, probably a ruby_block)."
        else
          location[:mechanism] = :'cookbook-other'
          location[:explanation] = "An attribute was set in a cookbook, but I don't recognize the calling pattern."
        end

        location[:cookbook] = nearest_frame[:cookbook]
        location[:file] = nearest_frame[:cookbook] + '/' + nearest_frame[:path_within_cookbook]
        location[:line] = nearest_frame[:line].to_i

        return location
      end

      def slh_looks_like_cookbook(stack)
        stack.find { |f| f[:cookbook] }
      end

      def slh_looks_like_attribute_reset(stack)
        reset_index = stack.find_index { |f| f[:method] == 'reset_defaults_and_attributes' }
        return ! reset_index.nil?
      end

      def slh_looks_like_cli_load(stack)
        # Heuristic: a call to consume attributes from consume_external_attrs
        consume_attributes_index = stack.find_index { |f| f[:method] == 'consume_attributes' }
        consume_attributes_index && stack[consume_attributes_index + 1][:method] == 'consume_external_attrs'
      end

      def slh_looks_like_ohai_bulk_load(stack)
        # Heuristic: a call to automatic_attrs= from consume_external_attrs
        aa_index = stack.find_index { |f| f[:method] == 'automatic_attrs=' }
        aa_index && stack[aa_index + 1][:method] == 'consume_external_attrs'
      end

      def slh_looks_like_ohai_platform_detection(stack)
        # Heuristic: a call to automatic[]= from consume_external_attrs with path == platform or platform version
        cae_index = stack.find_index { |f| f[:method] == 'consume_external_attrs' }        
        match = cae_index && stack[cae_index - 1][:method] == '[]='
        match &&= @component == :automatic
        match &&= ['/platform', '/platform_family', '/platform_version'].include?(@path)
        match
      end

      def slh_looks_like_role_load(stack)
        # Hueristic: a call to apply_role_attributes and component is role-ish
        ara_index = stack.find_index { |f| f[:method] == 'apply_role_attributes' }
        ara_index && [:role_default, :role_override].include?(@component)
      end

      def slh_looks_like_role_expansion_merge(stack)
        # Hueristic: a call to apply_expansion_attributes and component is role-ish
        aea_index = stack.find_index { |f| f[:method] == 'apply_expansion_attributes' }
        aea_index && [:role_default, :role_override].include?(@component)
      end

      def slh_looks_like_recipe_expansion_merge(stack)
        # Hueristic: a call to expand! and component is automatic
        frame_index = stack.find_index { |f| f[:method] == 'expand!' }
        frame_index && [:automatic].include?(@component)
      end

      def slh_looks_like_environment_load(stack)
        # Heuristic: a call to apply_expansion_attributes and component is env_default or env_override
        aea_index = stack.find_index { |f| f[:method] == 'apply_expansion_attributes' }
        aea_index && [:env_default, :env_override].include?(@component)
      end

      def slh_looks_like_node_construction_from_http(stack)
        # Heuristic: see json_create in node.rb, and handle_response in http/json_output
        match = true
        jc_index = stack.find_index { |f| f[:method] == 'json_create' && f[:file].end_with?('chef/node.rb') }
        match &&= jc_index && stack[jc_index, stack.length].find_index { |f| f[:method] == 'handle_response' && f[:file].end_with?('http/json_output.rb') }
        return match

      end

      public
      def pretty_callstack
        Kernel.caller.map do |frame|
          info = {}
          if m = frame.match(/^(?<file>[^:]+):(?<line>\d+)$/) 
            info[:file] = m[:file]
            info[:line] = m[:line]
          elsif m = frame.match(/^(?<file>[^:]+):(?<line>\d+):in `(?<method>[^']+)'$/)
            info[:file] = m[:file]
            info[:line] = m[:line]
            info[:method] = m[:method]
          end

          if info[:file]
            if m = info[:file].match(%r{/cookbooks/(?<cbname>[^/]+)/(?<cbpart>[^/]+)/(?<path>.+)})
              info[:cookbook] = m[:cbname]
              info[:cookbook_part] = m[:cbpart]
              info[:path_within_cookbook] = m[:cbpart] + '/' + m[:path]
            end
          end          
          info
        end
      end
    end

    class Attribute < Mash

      def find_path_to_entry(container)
        if container.respond_to?(:find_path_to_entry_ascent)           
          find_path_to_entry_ascent(container)
        else
          find_path_to_entry_descent(container)
        end
      end

      def find_path_to_entry_ascent(container)
        [ container.find_path_to_entry_ascent, container.component ]
      end

      def find_path_to_entry_descent(container, component=nil)
        # Container is a VividMash or a AttrArry, of which this object is the root.
        # Component is the precedence level - search in that VividMash, if known
        # Search for the container, and return the path and component to get to it.  

        # This is really stupid.
        components = component ? [ ('@' + component).to_sym ] : COMPONENTS
        components.each do |comp|
          starter_mash = instance_variable_get(comp)
          path = starter_mash.find_path_to_entry_descent(container)
          if path 
            return [ path, comp.to_s.sub('@', '') ]
          end
        end
        return nil
      end

      def trace_attribute_ignored_unless(collection, key, new_value)
        if Chef::Config.trace_attributes == 'none' then return end
          
        # A setting was attempted with ||= or set_unless, but a value already 
        # existed so the mutation was ignored

        # Determine the attrpath location of the change
        path, component = find_path_to_entry_ascent(collection)

        entry = AttributeTraceEntry.new(component, :set_unless_ignore)
        entry.value = new_value

        # Path might be nil, meaning that we have a collection whose root is us, but is not yet present in one of our component VividMash.  This can happen when a hash at least two levels deep is being directly assigned and boosted to being a VividMash.  In that case, the only think we can do is go ahead and trace the change, but postpone adding it to the log for a bit.
        # TODO: does this happen in this case?
        if path.nil?
          @trace_queue.push entry
          # Nothing else we can do at this point - later pases may be able to resolve the path.
          return
        else
          entry.path = path + (path == '/' ? '' : '/') + key.to_s
        end

        flush_queue
        add_entry_to_trace_log(entry)

      end

      def trace_attribute_change(collection, key, new_value)
        # A setting was made with =

        if Chef::Config.trace_attributes == 'none' then return end
          
        # Determine the attrpath location of the change
        path, component = find_path_to_entry_ascent(collection)
        unless path.nil?
          path += (path == '/' ? '' : '/') + key.to_s
        end

        entry = AttributeTraceEntry.new(component, :set, nil, path, new_value)

        # Path might be nil, meaning that we have a collection whose root is us, but is not yet present in one of our component VividMash.  This can happen when a hash at least two levels deep is being directly assigned and boosted to being a VividMash.  In that case, the only think we can do is go ahead and trace the change, but postpone adding it to the log for a bit.
        if path.nil?
          @trace_queue.push entry
          # Nothing else we can do at this point - later pases may be able to resolve the path.
          return
        end

        flush_queue
        add_entry_to_trace_log(entry)
      end

      

      def trace_attribute_clear(component)
        # the entire component-level Mash is about to be nuked

        if Chef::Config.trace_attributes == 'none' then return end
        
        entry = AttributeTraceEntry.new(component, :set, nil, '/', nil)
        entry.path = '/'

        flush_queue
        add_entry_to_trace_log(entry)
      end


      def append_trace_log(other_trace_log)
        other_trace_log.each do |path, incoming_entries|
          @trace_log[path] ||= []
          @trace_log[path] += incoming_entries
        end
      end


      private

      def trace_this_path?(attrpath)
        return true if Chef::Config.trace_attributes == 'all'
        return Chef::Config.trace_attributes == attrpath
      end


      def add_entry_to_trace_log(entry)
        return unless trace_this_path?(entry.path)

        # Log a set event for each
        @trace_log[entry.path] ||= []
        @trace_log[entry.path].push entry
        emit_log_message(entry)

        child_action = entry.action == :clear ? :clear : :parent_clobber

        # Log a parent-clobber for all extant children of this key
        @trace_log.keys.find_all do |p| 
          p.start_with?(entry.path) &&  # The path is a parent of this path....
            p != entry.path &&          # and is not this path....
              @trace_log[p].find { |ce| ce.component == entry.component }  # And at least one entry on this compoment exists for this path
        end.each do |child_path|
          child_entry = AttributeTraceEntry.new(entry.component, child_action, entry.source_location, child_path, nil)
          @trace_log[child_path].push child_entry 
          emit_log_message(child_entry)
        end
      end

      def emit_log_message(entry)
        msg = 'Attribute Trace:: '
        msg += 'path:' + entry.path + ', '
        msg += 'action:' + entry.action.to_s + ', '
        msg += 'precedence:' + entry.component.to_s + ', '
        msg += 'value:' + (entry.value.nil? ? '(nil)' : entry.value.to_s) + ', '
        msg += 'mechanism:' + entry.source_location[:mechanism].to_s + ', '
        details = entry.source_location[ entry.source_location.keys.sort.reject {|k| k == :mechanism } ]
        msg += 'source_details: ' + details.to_s
        Chef::Log.debug msg
      end

      def flush_queue
        # OK, try to flush the queue 

        @trace_queue.reject! do |ent|
          # We know we can't find it by ascent :(
          path, component = find_path_to_entry_descent(ent.value)
          if path
            # Hooray it resolved
            ent.path = path
            add_entry_to_trace_log(ent)
            true
          else
            # No soup for you
            false
          end
        end
      end

    end
  end
end
