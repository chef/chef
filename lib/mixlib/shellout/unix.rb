#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010, 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Mixlib
  class ShellOut
    module Unix

      # Option validation that is unix specific
      def validate_options(opts)
        # No options to validate, raise exceptions here if needed
      end

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
      #   within +timeout+ seconds (default: 600s)
      def run_command
        @child_pid = fork_subprocess

        configure_parent_process_file_descriptors

        # Ruby 1.8.7 and 1.8.6 from mid 2009 try to allocate objects during GC
        # when calling IO.select and IO#read. Some OS Vendors are not interested
        # in updating their ruby packages (Apple, *cough*) and we *have to*
        # make it work. So I give you this epic hack:
        GC.disable

        # CHEF-3390: Marshall.load on Ruby < 1.8.7p369 also has a GC bug related
        # to Marshall.load, so try disabling GC first.
        propagate_pre_exec_failure

        @result = nil
        @execution_time = 0

        write_to_child_stdin

        until @status
          ready = IO.select(open_pipes, nil, nil, READ_WAIT_TIME)
          unless ready
            @execution_time += READ_WAIT_TIME
            if @execution_time >= timeout && !@result
              raise CommandTimeout, "command timed out:\n#{format_for_exception}"
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
        @stdin_pipe, @stdout_pipe, @stderr_pipe, @process_status_pipe = IO.pipe, IO.pipe, IO.pipe, IO.pipe
        @process_status_pipe.last.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
      end

      def child_stdin
        @stdin_pipe[1]
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
        child_stdin.close   unless child_stdin.closed?
        child_stdout.close  unless child_stdout.closed?
        child_stderr.close  unless child_stderr.closed?
        child_process_status.close unless child_process_status.closed?
      end

      # Replace stdout, and stderr with pipes to the parent, and close the
      # reader side of the error marshaling side channel.
      #
      # If there is no input, close STDIN so when we exec,
      # the new program will know it's never getting input ever.
      def configure_subprocess_file_descriptors
        process_status_pipe.first.close

        # HACK: for some reason, just STDIN.close isn't good enough when running
        # under ruby 1.9.2, so make it good enough:
        stdin_pipe.last.close
        STDIN.reopen stdin_pipe.first
        stdin_pipe.first.close unless input

        stdout_pipe.first.close
        STDOUT.reopen stdout_pipe.last
        stdout_pipe.last.close

        stderr_pipe.first.close
        STDERR.reopen stderr_pipe.last
        stderr_pipe.last.close

        STDOUT.sync = STDERR.sync = true
        STDIN.sync = true if input
      end

      # When a new process is started with chef, it shares the file
      # descriptors of the parent. We clean the file descriptors
      # coming from the parent to prevent unintended locking if parent
      # is killed.
      # NOTE: After some discussions we've decided to iterate on file
      # descriptors upto 256. We believe this  is a reasonable upper
      # limit in a chef environment. If we have issues in the future this
      # number could be made to be configurable or updated based on
      # the ulimit based on platform.
      def clean_parent_file_descriptors
        # Don't clean $stdin, $stdout, $stderr, process_status_pipe.
        3.upto(256) do |n|
          # We are checking the fd for error pipe before attempting to
          # create a file because error pipe will auto close when we
          # try to create a file since it's set to CLOEXEC.
          if n != @process_status_pipe.last.to_i
            begin
              fd = File.for_fd(n)
              fd.close if fd
            rescue
            end
          end
        end
      end

      def configure_parent_process_file_descriptors
        # Close the sides of the pipes we don't care about
        stdin_pipe.first.close
        stdin_pipe.last.close unless input
        stdout_pipe.last.close
        stderr_pipe.last.close
        process_status_pipe.last.close
        # Get output as it happens rather than buffered
        child_stdin.sync = true if input
        child_stdout.sync = true
        child_stderr.sync = true

        true
      end

      # Some patch levels of ruby in wide use (in particular the ruby 1.8.6 on OSX)
      # segfault when you IO.select a pipe that's reached eof. Weak sauce.
      def open_pipes
        @open_pipes ||= [child_stdout, child_stderr]
      end

      # Keep this unbuffered for now
      def write_to_child_stdin
        return unless input
        child_stdin << input
        child_stdin.close # Kick things off
      end

      def read_stdout_to_buffer
        while chunk = child_stdout.read_nonblock(READ_SIZE)
          @stdout << chunk
          @live_stream << chunk if @live_stream
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete(child_stdout)
      end

      def read_stderr_to_buffer
        while chunk = child_stderr.read_nonblock(READ_SIZE)
          @stderr << chunk
        end
      rescue Errno::EAGAIN
      rescue EOFError
        open_pipes.delete(child_stderr)
      end

      def fork_subprocess
        initialize_ipc

        fork do
          configure_subprocess_file_descriptors

          clean_parent_file_descriptors

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
