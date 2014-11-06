class Chef
  class Audit
    class ControlGroupData
      attr_reader :name, :status, :number_success, :number_failed, :controls

      def initialize(name)
        @status = "success"
        @controls = []
        @number_success = 0
        @number_failed = 0
        @name = name
      end


      def example_success(opts={})
        @number_success += 1
        control = create_control(opts)
        control.status = "success"
        controls << control
        control
      end

      def example_failure(details=nil, opts={})
        @number_failed += 1
        @status = "failure"
        control = create_control(opts)
        control.details = details if details
        control.status = "failure"
        controls << control
        control
      end

      def to_hash
        controls.sort! {|x,y| x.line_number <=> y.line_number}
        {
            :control_group => {
                :name => name,
                :status => status,
                :number_success => number_success,
                :number_failed => number_failed,
                :controls => controls.collect { |c| c.to_hash }
            }
        }
      end

      private

      def create_control(opts={})
        name = opts[:name]
        resource_type = opts[:resource_type]
        resource_name = opts[:resource_name]
        context = opts[:context]
        ControlData.new(name, resource_type, resource_name, context)
      end

    end

    class ControlData
      attr_reader :name, :resource_type, :resource_name, :context
      attr_accessor :status, :details
      # TODO this only helps with debugging
      attr_accessor :line_number

      def initialize(name, resource_type, resource_name, context)
        @context = context
        @name = name
        @resource_type = resource_type
        @resource_name = resource_name
      end

      def to_hash
        ret = {
            :name => name,
            :status => status,
            :details => details,
            :resource_type => resource_type,
            :resource_name => resource_name
        }
        ret[:context] = context || []
        ret
      end
    end

  end
end
