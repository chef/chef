class Chef
  class Provider
    class Package
      class Yum
        # Simple implementation from rpm and ruby-rpm reference code
        class RPMDependency
          def initialize(*args)
            if args.size == 3
              @name = args[0]
              @version = RPMVersion.new(args[1])
              # Our requirement to other dependencies
              @flag = args[2] || :==
            elsif args.size == 5
              @name = args[0]
              e = args[1].to_i
              v = args[2]
              r = args[3]
              @version = RPMVersion.new(e,v,r)
              @flag = args[4] || :==
            else
              raise ArgumentError, "Expecting either 'name, epoch-version-release, flag' or " +
                "'name, epoch, version, release, flag'"
            end
          end
          attr_reader :name, :version, :flag

          # Parses 2 forms:
          #
          # "mtr >= 2:0.71-3.0"
          # "mta"
          def self.parse(string)
            if string =~ %r{^(\S+)\s+(>|>=|=|==|<=|<)\s+(\S+)$}
              name = $1
              if $2 == "="
                flag = :==
              else
                flag = :"#{$2}"
              end
              version = $3

              return self.new(name, version, flag)
            else
              name = string
              return self.new(name, nil, nil)
            end
          end

          # Test if another RPMDependency satisfies our requirements
          def satisfy?(y)
            unless y.kind_of?(RPMDependency)
              raise ArgumentError, "Expecting an RPMDependency object"
            end

            x = self

            # Easy!
            if x.name != y.name
              return false
            end

            # Partial compare
            #
            # eg: x.version 2.3 == y.version 2.3-1
            sense = x.version.partial_compare(y.version)

            # Thanks to rpmdsCompare() rpmds.c
            if sense < 0 and (x.flag == :> || x.flag == :>=) || (y.flag == :<= || y.flag == :<)
              return true
            elsif sense > 0 and (x.flag == :< || x.flag == :<=) || (y.flag == :>= || y.flag == :>)
              return true
            elsif sense == 0 and (
              ((x.flag == :== or x.flag == :<= or x.flag == :>=) and (y.flag == :== or y.flag == :<= or y.flag == :>=)) or
              (x.flag == :< and y.flag == :<) or
              (x.flag == :> and y.flag == :>)
            )
            return true
            end

            return false
          end
        end

        class RPMProvide < RPMDependency; end
        class RPMRequire < RPMDependency; end
      end
    end
  end
end

