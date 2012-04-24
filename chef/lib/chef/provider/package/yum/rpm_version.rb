class Chef
  class Provider
    class Package
      class Yum
        class RPMVersion
          include Comparable

          def initialize(*args)
            if args.size == 1
              @e, @v, @r = RPMUtils.version_parse(args[0])
            elsif args.size == 3
              @e = args[0].to_i
              @v = args[1]
              @r = args[2]
            else
              raise ArgumentError, "Expecting either 'epoch-version-release' or 'epoch, " +
                "version, release'"
            end
          end
          attr_reader :e, :v, :r
          alias :epoch :e
          alias :version :v
          alias :release :r

          def self.parse(*args)
            self.new(*args)
          end

          def <=>(y)
            compare_versions(y)
          end

          def compare(y)
            compare_versions(y, false)
          end

          def partial_compare(y)
            compare_versions(y, true)
          end

          # RPM::Version rpm_version_to_s equivalent
          def to_s
            if @r.nil?
              @v
            else
              "#{@v}-#{@r}"
            end
          end

          def evr
            "#{@e}:#{@v}-#{@r}"
          end

          private

          # Rough RPM::Version rpm_version_cmp equivalent - except much slower :)
          #
          # partial lets epoch and version segment equality be good enough to return equal, eg:
          #
          # 2:1.2-1 == 2:1.2
          # 2:1.2-1 == 2:
          #
          def compare_versions(y, partial=false)
            x = self

            # compare epoch
            if (x.e.nil? == false and x.e > 0) and y.e.nil?
              return 1
            elsif x.e.nil? and (y.e.nil? == false and y.e > 0)
              return -1
            elsif x.e.nil? == false and y.e.nil? == false
              if x.e < y.e
                return -1
              elsif x.e > y.e
                return 1
              end
            end

            # compare version
            if partial and (x.v.nil? or y.v.nil?)
              return 0
            elsif x.v.nil? == false and y.v.nil?
              return 1
            elsif x.v.nil? and y.v.nil? == false
              return -1
            elsif x.v.nil? == false and y.v.nil? == false
              cmp = RPMUtils.rpmvercmp(x.v, y.v)
              return cmp if cmp != 0
            end

            # compare release
            if partial and (x.r.nil? or y.r.nil?)
              return 0
            elsif x.r.nil? == false and y.r.nil?
              return 1
            elsif x.r.nil? and y.r.nil? == false
              return -1
            elsif x.r.nil? == false and y.r.nil? == false
              cmp = RPMUtils.rpmvercmp(x.r, y.r)
              return cmp
            end

            return 0
          end
        end
      end
    end
  end
end
