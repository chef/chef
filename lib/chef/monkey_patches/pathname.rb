require 'pathname'

if RUBY_VERSION.to_f < 1.9
  class Pathname
    @@old_each_filename = instance_method(:each_filename)

    def each_filename(&block)
      if block_given?
        EachFilenameEnumerable.new(self).each(&block)
      else
        EachFilenameEnumerable.new(self)
      end
    end

    def old_each_filename(&block)
      @@old_each_filename.bind(self).call(&block)
    end

    class EachFilenameEnumerable
      include Enumerable
      attr_reader :pathname

      def initialize(pathname)
        @pathname = pathname
      end

      def each(&block)
        @pathname.old_each_filename(&block)
      end
    end
  end
end
