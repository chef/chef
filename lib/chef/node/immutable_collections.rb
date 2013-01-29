
class Chef
  class Node

    module Immutablize
      def immutablize(value)
        case value
        when Hash
          ImmutableMash.new(value)
        when Array
          ImmutableArray.new(value)
        else
          value
        end
      end
    end

    # == ImmutableArray
    # ImmutableArray is used to implement Array collections when reading node
    # attributes.
    #
    # ImmutableArray acts like an ordinary Array, except:
    # * Methods that mutate the array are overridden to raise an error, making
    #   the collection more or less immutable.
    # * Since this class stores values computed from a parent
    #   Chef::Node::Attribute's values, it overrides all reader methods to
    #   detect staleness and raise an error if accessed when stale.
    class ImmutableArray < Array
      include Immutablize

      alias :internal_push :<<
      private :internal_push

      # A list of methods that mutate Array. Each of these is overridden to
      # raise an error, making this instances of this class more or less
      # immutable.
      DISALLOWED_MUTATOR_METHODS = [
        :<<,
        :[]=,
        :clear,
        :collect!,
        :compact!,
        :default=,
        :default_proc=,
        :delete,
        :delete_at,
        :delete_if,
        :fill,
        :flatten!,
        :insert,
        :keep_if,
        :map!,
        :merge!,
        :pop,
        :push,
        :update,
        :reject!,
        :reverse!,
        :replace,
        :select!,
        :shift,
        :slice!,
        :sort!,
        :sort_by!,
        :uniq!,
        :unshift
      ]

      def initialize(array_data)
        array_data.each do |value|
          internal_push(immutablize(value))
        end
      end

      # Redefine all of the methods that mutate a Hash to raise an error when called.
      # This is the magic that makes this object "Immutable"
      DISALLOWED_MUTATOR_METHODS.each do |mutator_method_name|
        # Ruby 1.8 blocks can't have block arguments, so we must use string eval:
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{mutator_method_name}(*args, &block)
            msg = "Node attributes are read-only when you do not specify which precedence level to set. " +
            %Q(To set an attribute use code like `node.default["key"] = "value"')
            raise Exceptions::ImmutableAttributeModification, msg
          end
        METHOD_DEFN
      end

      def dup
        Array.new(map {|e| e.dup })
      end

    end

    # == ImmutableMash
    # ImmutableMash implements Hash/Dict behavior for reading values from node
    # attributes.
    #
    # ImmutableMash acts like a Mash (Hash that is indifferent to String or
    # Symbol keys), with some important exceptions:
    # * Methods that mutate state are overridden to raise an error instead.
    # * Methods that read from the collection are overriden so that they check
    #   if the Chef::Node::Attribute has been modified since an instance of
    #   this class was generated. An error is raised if the object detects that
    #   it is stale.
    # * Values can be accessed in attr_reader-like fashion via method_missing.
    class ImmutableMash < Mash

      include Immutablize

      alias :internal_set :[]=
      private :internal_set

      DISALLOWED_MUTATOR_METHODS = [
        :[]=,
        :clear,
        :collect!,
        :default=,
        :default_proc=,
        :delete,
        :delete_if,
        :keep_if,
        :map!,
        :merge!,
        :update,
        :reject!,
        :replace,
        :select!,
        :shift
      ]

      def initialize(mash_data)
        mash_data.each do |key, value|
          internal_set(key, immutablize(value))
        end
      end

      alias :attribute? :has_key?

      # Redefine all of the methods that mutate a Hash to raise an error when called.
      # This is the magic that makes this object "Immutable"
      DISALLOWED_MUTATOR_METHODS.each do |mutator_method_name|
        # Ruby 1.8 blocks can't have block arguments, so we must use string eval:
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
        def #{mutator_method_name}(*args, &block)
          msg = "Node attributes are read-only when you do not specify which precedence level to set. " +
          %Q(To set an attribute use code like `node.default["key"] = "value"')
          raise Exceptions::ImmutableAttributeModification, msg
        end
        METHOD_DEFN
      end

      def method_missing(symbol, *args)
        if args.empty?
          if key?(symbol)
            self[symbol]
          else
            raise NoMethodError, "Undefined method or attribute `#{symbol}' on `node'"
          end
        # This will raise a ImmutableAttributeModification error:
        elsif symbol.to_s =~ /=$/
          key_to_set = symbol.to_s[/^(.+)=$/, 1]
          self[key_to_set] = (args.length == 1 ? args[0] : args)
        else
          raise NoMethodError, "Undefined node attribute or method `#{symbol}' on `node'"
        end
      end

      # Mash uses #convert_value to mashify values on input.
      # Since we're handling this ourselves, override it to be a no-op
      def convert_value(value)
        value
      end

      # NOTE: #default and #default= are likely to be pretty confusing. For a
      # regular ruby Hash, they control what value is returned for, e.g.,
      #   hash[:no_such_key] #=> hash.default
      # Of course, 'default' has a specific meaning in Chef-land

      def dup
        Mash.new(self)
      end

    end

  end
end
