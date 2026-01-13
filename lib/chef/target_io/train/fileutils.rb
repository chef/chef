module TargetIO
  module TrainCompat
    class FileUtils
      class << self
        def chmod(mode, list, noop: nil, verbose: nil)
          cmd = sprintf("chmod %s %s", __mode_to_s(mode), Array(list).join(" "))

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def chmod_R(mode, list, noop: nil, verbose: nil, force: nil)
          cmd = sprintf("chmod -R%s %s %s", (force ? "f" : ""), mode_to_s(mode), Array(list).join(" "))

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def chown(user, group, list, noop: nil, verbose: nil)
          cmd = sprintf("chown %s %s", (group ? "#{user}:#{group}" : user || ":"), Array(list).join(" "))

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def chown_R(user, group, list, noop: nil, verbose: nil, force: nil)
          cmd = sprintf("chown -R%s %s %s", (force ? "f" : ""), (group ? "#{user}:#{group}" : user || ":"), Array(list).join(" "))

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        # cmp
        # collect_method
        # commands
        # compare_file
        # compare_stream

        def cp(src, dest, preserve: nil, noop: nil, verbose: nil)
          cmd = "cp#{preserve ? " -p" : ""} #{[src, dest].flatten.join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end
        alias_method :copy, :cp

        def cp_lr(src, dest, noop: nil, verbose: nil, dereference_root: true, remove_destination: false)
          cmd = "cp -lr#{remove_destination ? " --remove-destination" : ""} #{[src, dest].flatten.join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def cp_r(src, dest, preserve: nil, noop: nil, verbose: nil, dereference_root: true, remove_destination: nil)
          cmd = "cp -r#{preserve ? "p" : ""}#{remove_destination ? " --remove-destination" : ""} #{[src, dest].flatten.join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        # getwd (alias pwd)
        # have_option?
        # identical? (alias compare_file)

        def install(src, dest, mode: nil, owner: nil, group: nil, preserve: nil, noop: nil, verbose: nil)
          cmd = "install -c"
          cmd << " -p" if preserve
          cmd << " -m " << mode_to_s(mode) if mode
          cmd << " -o #{owner}" if owner
          cmd << " -g #{group}" if group
          cmd << " " << [src, dest].flatten.join(" ")

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def ln(src, dest, force: nil, noop: nil, verbose: nil)
          cmd = "ln#{force ? " -f" : ""} #{[src, dest].flatten.join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end
        alias_method :link, :ln

        def ln_s(src, dest, force: nil, noop: nil, verbose: nil)
          cmd = "ln -s#{force ? "f" : ""} #{[src, dest].flatten.join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end
        alias_method :symlink, :ln_s

        def ln_sf(src, dest, noop: nil, verbose: nil)
          ln_s(src, dest, force: true, noop: noop, verbose: verbose)
        end

        def mkdir(list, mode: nil, noop: nil, verbose: nil)
          cmd = "mkdir #{mode ? ("-m %03o " % mode) : ""}#{Array(list).join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def mkdir_p(list, mode: nil, noop: nil, verbose: nil)
          cmd = "mkdir -p #{mode ? ("-m %03o " % mode) : ""}#{Array(list).join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end
        alias_method :makedirs, :mkdir_p
        alias_method :mkpath, :mkdir_p

        def mv(src, dest, force: nil, noop: nil, verbose: nil, secure: nil)
          cmd = "mv#{force ? " -f" : ""} #{[src, dest].flatten.join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        # options
        # options_of
        # pwd
        # remove
        # remove_entry_secure
        # remove_file

        def rm(list, force: nil, noop: nil, verbose: nil)
          cmd = "rm#{force ? " -f" : ""} #{Array(list).join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def rm_f(list, force: nil, noop: nil, verbose: nil, secure: nil)
          rm(list, force: true, noop: noop, verbose: verbose)
        end

        def rm_r(list, force: nil, noop: nil, verbose: nil, secure: nil)
          cmd = "rm -r#{force ? "f" : ""} #{Array(list).join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def rm_rf(list, noop: nil, verbose: nil, secure: nil)
          rm_r(list, force: true, noop: noop, verbose: verbose, secure: secure)
        end
        alias_method :remove_entry, :rm_rf
        alias_method :rmtree, :rm_rf
        alias_method :safe_unlink, :rm_rf

        def rmdir(list, parents: nil, noop: nil, verbose: nil)
          cmd = "rmdir #{parents ? "-p " : ""}#{Array(list).join(" ")}"

          Chef::Log.debug cmd if verbose
          return if noop

          __run_command(cmd)
        end

        def touch(list, noop: nil, verbose: nil, mtime: nil, nocreate: nil)
          return if noop

          __run_command "touch #{nocreate ? "-c " : ""}#{mtime ? mtime.strftime("-t %Y%m%d%H%M.%S ") : ""}#{Array(list).join(" ")}"
        end

        # uptodate?

        def method_missing(m, *_args, **_kwargs, &_block)
          raise "Unsupported #{self.class} method #{m}"
        end

        private

        # TODO: Symbolic modes
        def __mode_to_s(mode)
          mode.to_s(8)
        end

        def __run_command(cmd)
          __transport_connection.run_command(cmd)
        end

        def __transport_connection
          Chef.run_context&.transport_connection
        end
      end
    end
  end
end
