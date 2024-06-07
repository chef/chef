require_relative "file"

module TargetIO
  module TrainCompat
    class Etc
      @@cache = {}

      class << self
        def getpwnam(name)
          __getpw { |entry| entry["user"] == name }
        end

        def getpwuid(uid)
          __getpw { |entry| entry["uid"] == uid.to_i }
        end

        def getgrnam(name)
          __getgr { |entry| entry["name"] == name }
        end

        def getgrgid(gid)
          __getgr { |entry| entry["gid"] == gid.to_i }
        end

        def __getpw(&block)
          content = ::TargetIO::File.read("/etc/passwd")
          entries = __parse_passwd(content)
          data    = entries.detect(&block)
          raise ArgumentError unless data

          ::Etc::Passwd.new(
            data["user"],
            data["password"],
            data["uid"].to_i,
            data["gid"].to_i,
            data["desc"],
            data["home"],
            data["shell"]
          )
        end

        # Parse /etc/passwd files.
        # Courtesy of InSpec
        #
        # @param [String] content the raw content of /etc/passwd
        # @return [Array] Collection of passwd entries
        def __parse_passwd(content)
          content.to_s.split("\n").map do |line|
            next if line[0] == "#"

            __parse_passwd_line(line)
          end.compact
        end

        # Parse a line of /etc/passwd
        #
        # @param [String] line a line of /etc/passwd
        # @return [Hash] Map of entries in this line
        def __parse_passwd_line(line)
          x = line.split(":")
          {
            # rubocop:disable Layout/AlignHash
            "user"     => x.at(0),
            "password" => x.at(1),
            "uid"      => x.at(2),
            "gid"      => x.at(3),
            "desc"     => x.at(4),
            "home"     => x.at(5),
            "shell"    => x.at(6),
          }
        end

        def __getgr(&block)
          content = ::TargetIO::File.read("/etc/group")
          entries = __parse_group(content)
          data    = entries.detect(&block)
          raise ArgumentError unless data

          ::Etc::Group.new(
            data["name"],
            data["password"],
            data["gid"].to_i,
            String(data["mem"]).split(",")
          )
        end

        def __parse_group(content)
          content.to_s.split("\n").map do |line|
            next if line[0] == "#"

            __parse_group_line(line)
          end.compact
        end

        def __parse_group_line(line)
          x = line.split(":")
          {
            # rubocop:disable Layout/AlignHash
            "name"     => x.at(0),
            "password" => x.at(1),
            "gid"      => x.at(2),
            "mem"      => x.at(3),
          }
        end

        def __transport_connection
          Chef.run_context&.transport_connection
        end
      end
    end
  end
end
