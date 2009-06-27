#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/log'
require 'chef/exceptions'
require 'tmpdir'
require 'fcntl'
require 'etc'
require 'io/wait'

class Chef
  module Mixin
    module Command
      
      # If command is a block, returns true if the block returns true, false if it returns false.
      # ("Only run this resource if the block is true")
      #
      # If the command is not a block, executes the command.  If it returns any status other than
      # 0, it returns false (clearly, a 0 status code is true)
      #
      # === Parameters
      # command<Block>, <String>:: A block to check, or a string to execute
      #
      # === Returns
      # true:: Returns true if the block is true, or if the command returns 0
      # false:: Returns false if the block is false, or if the command returns a non-zero exit code.
      def only_if(command)
        if command.kind_of?(Proc)
          res = command.call
          unless res
            return false
          end
        else  
          status = run_command(:command => command, :ignore_failure => true)
          if status.exitstatus != 0
            return false
          end
        end
        true
      end
      
      module_function :only_if
      
      # If command is a block, returns false if the block returns true, true if it returns false.
      # ("Do not run this resource if the block is true")
      #
      # If the command is not a block, executes the command.  If it returns a 0 exitstatus, returns false.
      # ("Do not run this resource if the command returns 0")
      #
      # === Parameters
      # command<Block>, <String>:: A block to check, or a string to execute
      #
      # === Returns
      # true:: Returns true if the block is false, or if the command returns a non-zero exit status.
      # false:: Returns false if the block is true, or if the command returns a 0 exit status.
      def not_if(command)
        if command.kind_of?(Proc)
          res = command.call
          if res
            return false
          end
        else  
          status = run_command(:command => command, :ignore_failure => true)
          if status.exitstatus == 0
            return false
          end
        end
        true
      end
      
      module_function :not_if
     
      # === Parameters
      # args<Hash>: A number of required and optional arguments
      #   command<String>, <Array>: A complete command with options to execute or a command and options as an Array 
      #   creates<String>: The absolute path to a file that prevents the command from running if it exists
      #   cwd<String>: Working directory to execute command in, defaults to Dir.tmpdir
      #   timeout<String>: How many seconds to wait for the command to execute before timing out
      #   returns<String>: The single exit value command is expected to return, otherwise causes an exception
      #   ignore_failure<Boolean>: Whether to raise an exception on failure, or just return the status
      # 
      #   user<String>: The UID or user name of the user to execute the command as
      #   group<String>: The GID or group name of the group to execute the command as
      #   environment<Hash>: Pairs of environment variable names and their values to set before execution
      #
      # === Returns
      # Returns the exit status of args[:command]
      def run_command(args={})         
        command_output = ""
        
        args[:ignore_failure] ||= false

        if args.has_key?(:creates)
          if File.exists?(args[:creates])
            Chef::Log.debug("Skipping #{args[:command]} - creates #{args[:creates]} exists.")
            return false
          end
        end
        
        exec_processing_block = lambda do |pid, stdin, stdout, stderr|
          Chef::Log.debug("---- Begin output of #{args[:command]} ----")
          Chef::Log.debug("STDOUT: #{stdout.string.chomp}")
          Chef::Log.debug("STDERR: #{stderr.string.chomp}")
          command_output << "STDOUT: #{stdout.string.chomp}"
          command_output << "STDERR: #{stderr.string.chomp}"
          Chef::Log.debug("---- End output of #{args[:command]} ----")
        end
        
        args[:cwd] ||= Dir.tmpdir        
        unless File.directory?(args[:cwd])
          raise Chef::Exceptions::Exec, "#{args[:cwd]} does not exist or is not a directory"
        end
        
        Chef::Log.debug("Executing #{args[:command]}")
        
        status = nil
        
        Dir.chdir(args[:cwd]) do
          if args[:timeout]
            begin
              Timeout.timeout(args[:timeout]) do
                status = popen4(args[:command], args, &exec_processing_block)
              end
            rescue Timeout::Error => e
              Chef::Log.error("#{args[:command]} exceeded timeout #{args[:timeout]}")
              raise(e)
            end
          else
            status = popen4(args[:command], args, &exec_processing_block)
          end
          
          unless args[:ignore_failure] 
            args[:returns] ||= 0
            if status.exitstatus != args[:returns]
              # if the log level is not debug, through output of command when we fail
              output = ""
              if Chef::Log.logger.level > 0
                output << "\n---- Begin output of #{args[:command]} ----\n"
                output << "#{command_output}"
                output << "---- End output of #{args[:command]} ----\n"
              end
              raise Chef::Exceptions::Exec, "#{args[:command]} returned #{status.exitstatus}, expected #{args[:returns]}#{output}"
            end
          end
          Chef::Log.debug("Ran #{args[:command]} returned #{status.exitstatus}")
        end
        status
      end
      
      module_function :run_command
           
      # This is taken directly from Ara T Howard's Open4 library, and then 
      # modified to suit the needs of Chef.  Any bugs here are most likely
      # my own, and not Ara's.
      #
      # The original appears in external/open4.rb in its unmodified form. 
      #
      # Thanks Ara!
      def popen4(cmd, args={}, &b)
       
        # Waitlast - this is magic.  
        # 
        # Do we wait for the child process to die before we yield
        # to the block, or after?  That is the magic of waitlast.
        #
        # By default, we are waiting before we yield the block.
        args[:waitlast] ||= false
        
        args[:user] ||= nil
        unless args[:user].kind_of?(Integer)
          args[:user] = Etc.getpwnam(args[:user]).uid if args[:user]
        end
        args[:group] ||= nil
        unless args[:group].kind_of?(Integer)
          args[:group] = Etc.getgrnam(args[:group]).gid if args[:group]
        end
        args[:environment] ||= nil
        
        pw, pr, pe, ps = IO.pipe, IO.pipe, IO.pipe, IO.pipe

        verbose = $VERBOSE
        begin
          $VERBOSE = nil
          ps.last.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

          cid = fork {
            pw.last.close
            STDIN.reopen pw.first
            pw.first.close

            pr.first.close
            STDOUT.reopen pr.last
            pr.last.close

            pe.first.close
            STDERR.reopen pe.last
            pe.last.close

            STDOUT.sync = STDERR.sync = true

            if args[:group]
              Process.egid = args[:group]
              Process.gid = args[:group]
            end

            if args[:user]
              Process.euid = args[:user]
              Process.uid = args[:user]
            end
            
            if args[:environment]
              args[:environment].each do |key,value|
                ENV[key] = value
              end
            end

            if args[:umask]
              umask = ((args[:umask].respond_to?(:oct) ? args[:umask].oct : args[:umask].to_i) & 007777)
              File.umask(umask)
            end
            
            begin
              if cmd.kind_of?(Array)
                exec(*cmd)
              else
                exec(cmd)
              end
              raise 'forty-two' 
            rescue Exception => e
              Marshal.dump(e, ps.last)
              ps.last.flush
            end
            ps.last.close unless (ps.last.closed?)
            exit!
          }
        ensure
          $VERBOSE = verbose
        end

        [pw.first, pr.last, pe.last, ps.last].each{|fd| fd.close}

        begin
          e = Marshal.load ps.first
          raise(Exception === e ? e : "unknown failure!")
        rescue EOFError # If we get an EOF error, then the exec was successful
          42
        ensure
          ps.first.close
        end

        pw.last.sync = true

        pi = [pw.last, pr.first, pe.first]

        if b 
          begin
            if args[:waitlast]
              b[cid, *pi]
              Process.waitpid2(cid).last
            else
              # This took some doing.
              # The trick here is to close STDIN
              # Then set our end of the childs pipes to be O_NONBLOCK
              # Then wait for the child to die, which means any IO it
              # wants to do must be done - it's dead.  If it isn't,
              # it's because something totally skanky is happening,
              # and we don't care.
              o = StringIO.new
              e = StringIO.new

              pi[0].close
              
              stdout = pi[1]
              stderr = pi[2]

              stdout.sync = true
              stderr.sync = true

              stdout.fcntl(Fcntl::F_SETFL, pi[1].fcntl(Fcntl::F_GETFL) | Fcntl::O_NONBLOCK)
              stderr.fcntl(Fcntl::F_SETFL, pi[2].fcntl(Fcntl::F_GETFL) | Fcntl::O_NONBLOCK)
              
              stdout_finished = false
              stderr_finished = false
             
              results = nil

              while !stdout_finished || !stderr_finished
                begin
                  channels_to_watch = []
                  channels_to_watch << stdout if !stdout_finished
                  channels_to_watch << stderr if !stderr_finished
                  ready = IO.select(channels_to_watch, nil, nil, 1.0)
                rescue Errno::EAGAIN
                  results = Process.waitpid2(cid, Process::WNOHANG)
                  if results
                    stdout_finished = true
                    stderr_finished = true 
                  end
                end

                if ready && ready.first.include?(stdout)
                  line = results ? stdout.gets(nil) : stdout.gets
                  if line
                    o.write(line)
                  else
                    stdout_finished = true
                  end
                end
                if ready && ready.first.include?(stderr)
                  line = results ? stderr.gets(nil) : stderr.gets
                  if line
                    e.write(line)
                  else
                    stderr_finished = true
                  end
                end
              end
              results = Process.waitpid2(cid).last unless results
              o.rewind
              e.rewind
              b[cid, pi[0], o, e]
              results
            end
          ensure
            pi.each{|fd| fd.close unless fd.closed?}
          end
        else
          [cid, pw.last, pr.first, pe.first]
        end
      end      
      
      module_function :popen4

    end
  end
end
