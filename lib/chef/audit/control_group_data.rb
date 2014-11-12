require 'securerandom'

class Chef
  class Audit
    class AuditData
      attr_reader :node_name, :run_id, :control_groups

      def initialize(node_name, run_id)
        @node_name = node_name
        @run_id = run_id
        @control_groups = []
      end

      def add_control_group(control_group)
        control_groups << control_group
      end

      def to_hash
        {
            :node_name => node_name,
            :run_id => run_id,
            :control_groups => control_groups.collect { |c| c.to_hash }
        }
      end
    end

    class ControlGroupData
      attr_reader :name, :status, :number_success, :number_failed, :controls

      def initialize(name)
        @status = "success"
        @controls = []
        @number_success = 0
        @number_failed = 0
        @name = name
      end


      def example_success(control_data)
        @number_success += 1
        control = create_control(control_data)
        control.status = "success"
        controls << control
        control
      end

      def example_failure(control_data, details)
        @number_failed += 1
        @status = "failure"
        control = create_control(control_data)
        control.details = details if details
        control.status = "failure"
        controls << control
        control
      end

      def to_hash
        # We sort it so the examples appear in the output in the same order
        # they appeared in the recipe
        controls.sort! {|x,y| x.line_number <=> y.line_number}
        h = {
              :name => name,
              :status => status,
              :number_success => number_success,
              :number_failed => number_failed,
              :controls => controls.collect { |c| c.to_hash }
        }
        add_display_only_data(h)
      end

      private

      def create_control(control_data)
        name = control_data[:name]
        resource_type = control_data[:resource_type]
        resource_name = control_data[:resource_name]
        context = control_data[:context]
        line_number = control_data[:line_number]
        # TODO make this smarter with splat arguments so if we start passing in more control_data
        # I don't have to modify code in multiple places
        ControlData.new(name, resource_type, resource_name, context, line_number)
      end

      # The id and control sequence number are ephemeral data - they are not needed
      # to be persisted and can be regenerated at will.  They are only needed
      # for display purposes.
      def add_display_only_data(group)
        group[:id] = SecureRandom.uuid
        group[:controls].collect!.with_index do |c, i|
          # i is zero-indexed, and we want the display one-indexed
          c[:sequence_number] = i+1
          c
        end
        group
      end

    end

    class ControlData
      attr_reader :name, :resource_type, :resource_name, :context, :line_number
      attr_accessor :status, :details

      def initialize(name, resource_type, resource_name, context, line_number)
        @context = context
        @name = name
        @resource_type = resource_type
        @resource_name = resource_name
        @line_number = line_number
      end

      def to_hash
        h = {
            :name => name,
            :status => status,
            :details => details,
            :resource_type => resource_type,
            :resource_name => resource_name
        }
        h[:context] = context || []
        h
      end
    end

  end
end
