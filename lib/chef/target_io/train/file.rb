module TargetIO
  module TrainCompat
    class File
      class << self
        def foreach(name)
          raise "TargetIO does not implement block-less File.foreach yet" unless block_given?

          contents = readlines(name)
          contents.each { |line| yield(line) }
        end

        def binread(name, length = nil, offset = 0)
          content = read(file_name)
          length = content.size - offset if length.nil?

          content[offset, length]
        end

        def expand_path(file_name, dir_string = "")
          require "pathname" unless defined?(Pathname)

          # Will just collapse relative paths inside
          pn = Pathname.new File.join(dir_string, file_name)
          pn.cleanpath
        end

        def new(filename, mode = "r")
          # Would need to hook into io.close (Closure?)
          raise NotImplementedError, "TargetIO does not implement File.new yet"
        end

        def read(file_name)
          readlines(file_name)&.join("\n") || ""
        end

        def open(file_name, mode = "r")
          # Would need to hook into io.close (Closure?)
          raise "TargetIO does not implement block-less File.open with modes other than read yet" if mode != "r" && !block_given?

          content = exist?(file_name) ? read(file_name) : ""
          new_content = content.dup

          io = StringIO.new(new_content)

          if mode.start_with? "w"
            io.truncate(0)
          elsif mode.start_with? "a"
            io.seek(0, IO::SEEK_END)
          end

          if block_given?
            yield(io)

            if (content != new_content) && !mode.start_with?("r")
              __transport_connection.file(file_name).content = new_content # Need Train 2.5+
            end
          end

          io
        end

        def readlines(file_name)
          content = __transport_connection.file(file_name).content
          raise Errno::ENOENT if content.nil? # Not found

          content.split("\n")
        end

        ### START Could be in Train::File::...

        def executable?(file_name)
          mode(file_name) & 0111 != 0
        end

        def readable?(file_name)
          cmd = format("test -r %s", file_name)
          __transport_connection.run_command(cmd).exit_status == 0
        end

        def writable?(file_name)
          cmd = format("test -w %s", file_name)
          __transport_connection.run_command(cmd).exit_status == 0
        end

        # def ftype(file_name)
        #   case type(file_name)
        #   when :block_device
        #     "blockSpecial"
        #   when :character_device
        #     "characterSpecial"
        #   when :symlink
        #     "link"
        #   else
        #     type(file_name).to_s
        #   end
        # end

        def realpath(file_name)
          cmd = "realpath #{file_name}" # coreutils, not MacOSX
          Chef::Log.debug cmd

          __transport_connection.run_command(cmd).stdout.chop
        end

        def readlink(file_name)
          raise Errno::EINVAL unless symlink?(file_name)

          cmd = "readlink #{file_name}"
          Chef::Log.debug cmd

          __transport_connection.run_command(cmd).stdout.chop
        end

        # def setgid?(file_name)
        #   mode(file_name) & 04000 != 0
        # end

        # def setuid?(file_name)
        #   mode(file_name) & 02000 != 0
        # end

        # def sticky?(file_name)
        #   mode(file_name) & 01000 != 0
        # end

        # def size?(file_name)
        #   exist?(file_name) && size(file_name) > 0
        # end

        # def world_readable?(file_name)
        #   mode(file_name) & 0001 != 0
        # end

        # def world_writable?(file_name)
        #   mode(file_name) & 0002 != 0
        # end

        # def zero?(file_name)
        #   exists?(file_name) && size(file_name) == 0
        # end

        ### END: Could be in Train

        # passthrough or map calls to third parties
        def method_missing(m, *args, **kwargs, &block)
          nonio    = %i{extname join dirname path split}

          # TODO: writable?
          passthru = %i{basename directory? exist? exists? file? path pipe? socket? symlink?}
          redirect_train = {
            blockdev?: :block_device?,
            chardev?: :character_device?,
          }
          redirect_utils = {
            chown: :chown,
            chmod: :chmod,
            symlink: :ln_s,
            delete: :rm,
            unlink: :rm,
          }
          filestat = %i{gid group mode owner selinux_label size uid}

          if %i{stat lstat}.include? m
            Chef::Log.debug "File::#{m} passed to Train.file.stat"

            follow_symlink = m == :stat
            tfile = __transport_connection.file(args[0], follow_symlink).stat

            require "ostruct" unless defined?(OpenStruct)
            OpenStruct.new(tfile)

          # Non-IO methods can be issued locally
          elsif nonio.include? m
            ::File.send(m, *args, **kwargs) # TODO: pass block

          elsif passthru.include? m
            Chef::Log.debug "File::#{m} passed to Train.file.#{m}"

            file_name, other_args = args[0], args[1..]

            file = __transport_connection.file(file_name)
            file.send(m, *other_args, **kwargs) # block?

          elsif m == :mtime
            # Solve a data type disparity between Train.file and File
            timestamp = __transport_connection.file(args[0]).mtime
            Time.at(timestamp)

          elsif filestat.include? m
            Chef::Log.debug "File::#{m} passed to Train.file.stat.#{m}"

            __transport_connection.file(args[0]).stat[m]

          elsif redirect_utils.key?(m)
            new_method = redirect_utils[m]
            Chef::Log.debug "File::#{m} redirected to TargetIO::FileUtils.#{new_method}"

            ::TargetIO::FileUtils.send(new_method, *args, **kwargs) # TODO: pass block

          elsif redirect_train.key?(m)
            new_method = redirect_train[m]
            Chef::Log.debug "File::#{m} redirected to Train.file.#{new_method}"

            file_name, other_args = args[0], args[1..]

            file = __transport_connection.file(file_name)
            file.send(redirect[m], *other_args, **kwargs) # TODO: pass block

          else
            raise "Unsupported File method #{m}"
          end
        end

        def __transport_connection
          Chef.run_context&.transport_connection
        end
      end
    end
  end
end
