module TargetIO
  module TrainCompat
    module Shadow
      # @see https://www.rubydoc.info/gems/ruby-shadow/2.5.0
      class Passwd
        class << self
          def getspnam(name)
            content = ::TargetIO::File.read("/etc/shadow")
            entries = __parse_shadow(content)
            data    = entries.detect { |entry| entry["name"] == name }
            return ::TargetIO::Shadow::Entry.new unless data

            ::TargetIO::Shadow::Entry.new(
              data["sp_namp"],
              data["sp_pwdp"],
              data["sp_lstchg"],
              data["sp_min"],
              data["sp_max"],
              data["sp_warn"],
              data["sp_inact"],
              data["sp_expire"],
              data["sp_loginclass"]
            )
          end

          def __parse_shadow(content)
            content.to_s.split("\n").map do |line|
              next if line[0] == "#"

              __parse_shadow_line(line)
            end.compact
          end

          def __parse_shadow_line(line)
            x = line.split(":")
            {
              # rubocop:disable Layout/AlignHash
              "sp_namp"   => x.at(0),
              "sp_pwdp"   => x.at(1),
              "sp_lstchg" => x.at(2),
              "sp_min"    => x.at(3),
              "sp_max"    => x.at(4),
              "sp_warn"   => x.at(5),
              "sp_inact"  => x.at(6),
              "sp_expire" => x.at(7),
            }
          end
        end
      end
    end
  end
end
