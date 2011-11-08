class Chef
  class ShellOut
    module Unix

      # Run the command, writing the command's standard out and standard error
      # to +stdout+ and +stderr+, and saving its exit status object to +status+
      # === Returns
      # returns   +self+; +stdout+, +stderr+, +status+, and +exitstatus+ will be
      # populated with results of the command
      # === Raises
      # * Errno::EACCES  when you are not privileged to execute the command
      # * Errno::ENOENT  when the command is not available on the system (or not
      #   in the current $PATH)
      # * Chef::Exceptions::CommandTimeout  when the command does not complete
      #   within +timeout+ seconds (default: 60s)
      def run_command
        @child_pid = fork_subprocess

        configure_parent_process_file_descriptors
        propagate_pre_exec_failure

        @result = nil
        @execution_time = 0

        # Ruby 1.8.7 and 1.8.6 from mid 2009 try to allocate objects during GC
        # when calling IO.select and IO#read. Some OS Vendors are not interested
        # in updating their ruby packages (Apple, *cough*) and we *have to*
        # make it work. So I give you this epic hack:
        GC.disable
        until @status
          ready = IO.select(open_pipes, nil, nil, READ_WAIT_TIME)
          unless ready
            @execution_time += READ_WAIT_TIME
            if @execution_time >= timeout && !@result
              raise Chef::Exceptions::CommandTimeout, "command timed out:\n#{format_for_exception}"
            end
          end

          if ready && ready.first.include?(child_stdout)
            read_stdout_to_buffer
          end
          if ready && ready.first.include?(child_stderr)
            read_stderr_to_buffer
          end

          unless @status
            # make one more pass to get the last of the output after the
            # child process dies
            if results = Process.waitpid2(@child_pid, Process::WNOHANG)
              @status = results.last
              redo
            end
          end
        end
        self
      rescue Exception
        # do our best to kill zombies
        Process.waitpid2(@child_pid, Process::WNOHANG) rescue nil
        raise
      ensure
        # no matter what happens, turn the GC back on, and hope whatever busted
        # version of ruby we're on doesn't allocate some objects during the next
        # GC run.
        GC.enable
        close_all_pipes
      end

      private

      def set_user
        if user
          Process.euid = uid
          Process.uid = uid
        end
      end

      def set_group
        if group
          Process.egid = gid
          Process.gid = gid
        end
      end

      def set_environment
        environment.each do |env_var,value|
          ENV[env_var] = value
        end
      end

      def set_umask
        File.umask(umask) if umask
      end

      def set_cwd
        Dir.chdir(cwd) if cwd
      end

      def initialize_ipc
        @stdout_pipe, @stderr_pipe, @process_status_pipe = IO.pipe, IO.pipe, IO.pipe
        @process_status_pipe.last.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
      end

      def child_stdout
        @stdout_pipe[0]
      end

      def child_stderr
        @stderr_pipe[0]
      end

      def child_process_status
        @process_status_pipe[0]
      end

      def close_all_pipes
        child_stdout.close  unless child_stdout.closed?
        child_stderr.close  unless child_stderr.closed?
        child_process_status.close unless child_process_status.closed?
      end

      # replace stdout, and stderr with pipes to the parent, and close the
      # reader side of the error marshaling side channel. Close STDIN so when we
      # exec, the new program will know it's never getting input ever.
      def configure_subprocess_file_descriptors
        process_status_pipe.first.close

        # HACK: for some reason, just STDIN.close isn't good enough when running
        # under ruby 1.9.2, so make it good enough:
        stdin_reader, stdin_writer = IO.pipe
        stdin_writer.close
        STDIN.reopen stdin_reader
        stdin_reader.close

        stdout_pipe.first.close
        STDOUT.reopen stdout_pipe.last
        stdout_pipe.last.close

        stderr_pipe.first.close
        STDERR.reopen stderr_pipe.last
        stderr_pipe.last.close

        STDOUT.sync = STDERR.sync = true
      end

      def configure_parent_process_file_descriptors
        # Close the sides of the pipes we don't care about
        stdout_pipe.last.close
        stderr_pipe.last.close
        process_status_pipe.last.close
        # Get output as it happens rather than buffered
        child_stdout.sync = true
        child_stderr.sync = true

        true
      end

      # Some patch levels of ruby in wide use (in particular the ruby 1.8.6 on OSX)
      # segfault when you IO.select a pipe that's reached eof. Weak sauce.
      def open_pipes
        @open_pipes ||= [child_stdout, child_stderr]
      end

      def read_stdout_to_buffer
        while chunk = child_stdout.read_nonblock(READ_SIZE)
          @stdout << chunk
          @live_stream << chunk if @live_stream
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete_at(0)
      end

      def read_stderr_to_buffer
        while chunk = child_stderr.read_nonblock(READ_SIZE)
          @stderr << chunk
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete_at(1)
      end

      def fork_subprocess
        initialize_ipc

        fork do
          configure_subprocess_file_descriptors

          set_group
          set_user
          set_environment
          set_umask
          set_cwd

          begin
            command.kind_of?(Array) ? exec(*command) : exec(command)

            raise 'forty-two' # Should never get here
          rescue Exception => e
            Marshal.dump(e, process_status_pipe.last)
            process_status_pipe.last.flush
          end
          process_status_pipe.last.close unless (process_status_pipe.last.closed?)
          exit!
        end
      end

      # Attempt to get a Marshaled error from the side-channel.
      # If it's there, un-marshal it and raise. If it's not there,
      # assume everything went well.
      def propagate_pre_exec_failure
        begin
          e = Marshal.load child_process_status
          raise(Exception === e ? e : "unknown failure: #{e.inspect}")
        rescue EOFError # If we get an EOF error, then the exec was successful
          true
        ensure
          child_process_status.close
        end
      end

    end
  end
end
