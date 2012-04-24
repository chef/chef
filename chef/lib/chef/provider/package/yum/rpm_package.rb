class Chef
  class Provider
    class Package
      class Yum
        class RPMPackage
          include Comparable

          def initialize(*args)
            if args.size == 4
              @n = args[0]
              @version = RPMVersion.new(args[1])
              @a = args[2]
              @provides = args[3]
            elsif args.size == 6
              @n = args[0]
              e = args[1].to_i
              v = args[2]
              r = args[3]
              @version = RPMVersion.new(e,v,r)
              @a = args[4]
              @provides = args[5]
            else
              raise ArgumentError, "Expecting either 'name, epoch-version-release, arch, provides' " +
                "or 'name, epoch, version, release, arch, provides'"
            end

            # We always have one, ourselves!
            if @provides.empty?
              @provides = [ RPMProvide.new(@n, @version.evr, :==) ]
            end
          end
          attr_reader :n, :a, :version, :provides
          alias :name :n
          alias :arch :a

          def <=>(y)
            compare(y)
          end

          def compare(y)
            x = self

            # easy! :)
            return 0 if x.nevra == y.nevra

            # compare name
            if x.n.nil? == false and y.n.nil?
              return 1
            elsif x.n.nil? and y.n.nil? == false
              return -1
            elsif x.n.nil? == false and y.n.nil? == false
              if x.n < y.n
                return -1
              elsif x.n > y.n
                return 1
              end
            end

            # compare version
            if x.version > y.version
              return 1
            elsif x.version < y.version
              return -1
            end

            # compare arch
            if x.a.nil? == false and y.a.nil?
              return 1
            elsif x.a.nil? and y.a.nil? == false
              return -1
            elsif x.a.nil? == false and y.a.nil? == false
              if x.a < y.a
                return -1
              elsif x.a > y.a
                return 1
              end
            end

            return 0
          end

          def to_s
            nevra
          end

          def nevra
            "#{@n}-#{@version.evr}.#{@a}"
          end
        end

        class RPMDbPackage < RPMPackage
          # <rpm parts>, installed, available
          def initialize(*args)
            @repoid = args.pop
            # state
            @available = args.pop
            @installed = args.pop
            super(*args)
          end
          attr_reader :repoid, :available, :installed
        end
      end
    end
  end
end
