#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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


require 'tmpdir'
require 'fcntl'
require 'etc'

class Chef
  module Mixin
    module Command
      
      def run_command(args={})         
        if args.has_key?(:creates)
          if File.exists?(args[:creates])
            Chef::Log.debug("Skipping #{args[:command_string]} - creates #{args[:creates]} exists.")
            return false
          end
        end
        
        if args.has_key?(:only_if)
          if Proc === args[:only_if]
            res = args[:only_if].call
            unless res
              Chef::Log.debug("Skipping #{args[:command_string]} - onlyif #{args[:only_if]}")
              return false
            end    
          else  
            status = popen4(args[:only_if]) { |p, i, o, e| }
            if status.exitstatus != 0
              Chef::Log.debug("Skipping #{args[:command_string]} - onlyif #{args[:only_if]} returned #{status.exitstatus}")
              return false
            end
          end  
        end
        
        if args.has_key?(:not_if)
          if Proc === args[:not_if]
            res = args[:not_if].call
            unless res
              Chef::Log.debug("Skipping #{args[:command_string]} - onlyif #{args[:not_if]}")
              return false
            end    
          else
            Chef::Log.debug("I should be running '#{args[:not_if]}'")
            status = popen4(args[:not_if]) { |p, i, o, e| }
            if status.exitstatus == 0
              Chef::Log.debug("Skipping #{args[:command_string]} - unless #{args[:not_if]} returned #{status.exitstatus}")
              return false
            end
          end  
        end
        
        exec_processing_block = lambda do |pid, stdin, stdout, stderr|
          stdin.close

          stdout_string = stdout.gets(nil)
          if stdout_string
            Chef::Log.debug("---- Begin #{args[:command_string]} STDOUT ----")
            Chef::Log.debug(stdout_string.strip)
            Chef::Log.debug("---- End #{args[:command_string]} STDOUT ----")
          end
          stderr_string = stderr.gets(nil)
          if stderr_string
            Chef::Log.debug("---- Begin #{args[:command_string]} STDERR ----")
            Chef::Log.debug(stderr_string.strip)
            Chef::Log.debug("---- End #{args[:command_string]} STDERR ----")
          end
        end
        
        args[:cwd] ||= Dir.tmpdir        
        unless File.directory?(args[:cwd])
          raise Chef::Exception::Exec, "#{args[:cwd]} does not exist or is not a directory"
        end
        
        status = nil
        Dir.chdir(args[:cwd]) do
          if args[:timeout]
            begin
              Timeout.timeout(args[:timeout]) do
                status = popen4(args[:command], args, &exec_processing_block)
              end
            rescue Exception => e
              Chef::Log.error("#{args[:command_string]} exceeded timeout #{args[:timeout]}")
              raise(e)
            end
          else
            status = popen4(args[:command], args, &exec_processing_block)
          end
        
          args[:returns] ||= 0
          if status.exitstatus != args[:returns]
            raise Chef::Exception::Exec, "#{args[:command_string]} returned #{status.exitstatus}, expected #{args[:returns]}"
          else
            Chef::Log.debug("Ran #{args[:command_string]} (#{args[:command]}) returned #{status.exitstatus}")
          end
        end
        status
      end
      
      module_function :run_command
           
      # This is taken directly from Ara T Howard's Open4 library, and then 
      # modified to suit the needs of Chef.  Any bugs here are most likely
      # my own, and not Ara's.
      #
      # The original appears in external/open4.rb in it's unmodified form. 
      #
      # Thanks, Ara. 
      def popen4(cmd, args={}, &b)
        
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

            if args[:user]
              Process.euid = args[:user]
              Process.uid = args[:user]
            end
            
            if args[:group]
              Process.egid = args[:group]
              Process.gid = args[:group]
            end
            
            if args[:environment]
              args[:environment].each do |key,value|
                ENV[key] = value
              end
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
            b[cid, *pi]
            Process.waitpid2(cid).last
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