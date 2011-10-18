#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'win32/process'
require 'windows/handle'
require 'windows/process'
require 'windows/synchronize'

class Chef
  class ShellOut
    module Windows

      include ::Windows::Handle
      include ::Windows::Process
      include ::Windows::Synchronize

      TIME_SLICE = 0.05

      #--
      # Missing lots of features from the UNIX version, such as
      # uid, etc.
      def run_command

        #
        # Create pipes to capture stdout and stderr,
        #
        stdout_read, stdout_write = IO.pipe
        stderr_read, stderr_write = IO.pipe
        open_streams = [ stdout_read, stderr_read ]

        begin

          #
          # Set cwd, environment, appname, etc.
          #
          create_process_args = {
            :app_name => ENV['COMSPEC'],
            :command_line => "cmd /c #{command}",
            :startup_info => {
              :stdout => stdout_write,
              :stderr => stderr_write
            },
            :environment => inherit_environment.map { |k,v| "#{k}=#{v}" },
            :close_handles => false
          }
          create_process_args[:cwd] = cwd if cwd

          #
          # Start the process
          #
          process = Process.create(create_process_args)
          begin

            #
            # Wait for the process to finish, consuming output as we go
            #
            start_wait = Time.now
            while true
              wait_status = WaitForSingleObject(process.process_handle, 0)
              case wait_status
                when WAIT_OBJECT_0
                  # Get process exit code
                  exit_code = [0].pack('l')
                  unless GetExitCodeProcess(process.process_handle, exit_code)
                    raise get_last_error
                  end
                  @status = ThingThatLooksSortOfLikeAProcessStatus.new
                  @status.exitstatus = exit_code.unpack('l').first

                  return self
                when WAIT_TIMEOUT
                  # Kill the process
                  if (Time.now - start_wait) > timeout
                    raise Chef::Exceptions::CommandTimeout, "command timed out:\n#{format_for_exception}"
                  end

                  consume_output(open_streams, stdout_read, stderr_read)
                else
                  raise "Unknown response from WaitForSingleObject(#{process.process_handle}, #{timeout*1000}): #{wait_status}"
              end

            end

          ensure
            CloseHandle(process.thread_handle)
            CloseHandle(process.process_handle)
          end

        ensure
          #
          # Consume all remaining data from the pipes until they are closed
          #
          stdout_write.close
          stderr_write.close

          while consume_output(open_streams, stdout_read, stderr_read)
          end
        end
      end

      private

      class ThingThatLooksSortOfLikeAProcessStatus
        attr_accessor :exitstatus
      end

      def consume_output(open_streams, stdout_read, stderr_read)
        return false if open_streams.length == 0
        ready = IO.select(open_streams, nil, nil, READ_WAIT_TIME)
        return true if ! ready

        if ready.first.include?(stdout_read)
          begin
            next_chunk = stdout_read.readpartial(READ_SIZE)
            @stdout << next_chunk
            @live_stream << next_chunk if @live_stream
          rescue EOFError
            stdout_read.close
            open_streams.delete(stdout_read)
          end
        end

        if ready.first.include?(stderr_read)
          begin
            @stderr << stderr_read.readpartial(READ_SIZE)
          rescue EOFError
            stderr_read.close
            open_streams.delete(stderr_read)
          end
        end

        return true
      end

      def inherit_environment
        result = {}
        ENV.each_pair do |k,v|
          result[k] = v
        end

        environment.each_pair do |k,v|
          if v != nil
            result.delete(k)
          else
            result[k] = v
          end
        end
        result
      end
    end # class
  end
end

#
# Override module Windows::Process.CreateProcess to fix bug when
# using both app_name and command_line
#
module Windows
  module Process
    API.new('CreateProcess', 'SPPPLLLPPP', 'B')
  end
end

#
# Override Win32::Process.create to take a proper environment hash
# so that variables can contain semicolons
# (submitted patch to owner)
#
module Process
  def create(args)
    unless args.kind_of?(Hash)
      raise TypeError, 'Expecting hash-style keyword arguments'
    end
      
    valid_keys = %w/
      app_name command_line inherit creation_flags cwd environment
      startup_info thread_inherit process_inherit close_handles with_logon
      domain password
    /

    valid_si_keys = %/
      startf_flags desktop title x y x_size y_size x_count_chars
      y_count_chars fill_attribute sw_flags stdin stdout stderr
    /

    # Set default values
    hash = {
      'app_name'       => nil,
      'creation_flags' => 0,
      'close_handles'  => true
    }
      
    # Validate the keys, and convert symbols and case to lowercase strings.     
    args.each{ |key, val|
      key = key.to_s.downcase
      unless valid_keys.include?(key)
        raise ArgumentError, "invalid key '#{key}'"
      end
      hash[key] = val
    }
      
    si_hash = {}
      
    # If the startup_info key is present, validate its subkeys
    if hash['startup_info']
      hash['startup_info'].each{ |key, val|
        key = key.to_s.downcase
        unless valid_si_keys.include?(key)
          raise ArgumentError, "invalid startup_info key '#{key}'"
        end
        si_hash[key] = val
      }
    end
      
    # The +command_line+ key is mandatory unless the +app_name+ key
    # is specified.
    unless hash['command_line']
      if hash['app_name']
        hash['command_line'] = hash['app_name']
        hash['app_name'] = nil
      else
        raise ArgumentError, 'command_line or app_name must be specified'
      end
    end
      
    # The environment string should be passed as an array of A=B paths, or
    # as a string of ';' separated paths.
    if hash['environment']
      env = hash['environment']
      if !env.respond_to?(:join)
        # Backwards compat for ; separated paths
        env = hash['environment'].split(File::PATH_SEPARATOR)
      end
      # The argument format is a series of null-terminated strings, with an additional null terminator.
      env = env.map { |e| e + "\0" }.join("") + "\0"
      if hash['with_logon']
        env = env.multi_to_wide(e)
      end
      env = [env].pack('p*').unpack('L').first
    else
      env = nil
    end

    startinfo = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    startinfo = startinfo.pack('LLLLLLLLLLLLSSLLLL')
    procinfo  = [0,0,0,0].pack('LLLL')

    # Process SECURITY_ATTRIBUTE structure
    process_security = 0
    if hash['process_inherit']
      process_security = [0,0,0].pack('LLL')
      process_security[0,4] = [12].pack('L') # sizeof(SECURITY_ATTRIBUTE)
      process_security[8,4] = [1].pack('L')  # TRUE
    end

    # Thread SECURITY_ATTRIBUTE structure
    thread_security = 0
    if hash['thread_inherit']
      thread_security = [0,0,0].pack('LLL')
      thread_security[0,4] = [12].pack('L') # sizeof(SECURITY_ATTRIBUTE)
      thread_security[8,4] = [1].pack('L')  # TRUE
    end

    # Automatically handle stdin, stdout and stderr as either IO objects
    # or file descriptors.  This won't work for StringIO, however.
    ['stdin', 'stdout', 'stderr'].each{ |io|
      if si_hash[io]
        if si_hash[io].respond_to?(:fileno)
          handle = get_osfhandle(si_hash[io].fileno)
        else
          handle = get_osfhandle(si_hash[io])
        end
            
        if handle == INVALID_HANDLE_VALUE
          raise Error, get_last_error
        end

        # Most implementations of Ruby on Windows create inheritable
        # handles by default, but some do not. RF bug #26988.
        bool = SetHandleInformation(
          handle,
          HANDLE_FLAG_INHERIT,
          HANDLE_FLAG_INHERIT
        )

        raise Error, get_last_error unless bool
            
        si_hash[io] = handle
        si_hash['startf_flags'] ||= 0
        si_hash['startf_flags'] |= STARTF_USESTDHANDLES
        hash['inherit'] = true
      end
    }
      
    # The bytes not covered here are reserved (null)
    unless si_hash.empty?
      startinfo[0,4]  = [startinfo.size].pack('L')
      startinfo[8,4]  = [si_hash['desktop']].pack('p*') if si_hash['desktop']
      startinfo[12,4] = [si_hash['title']].pack('p*') if si_hash['title']
      startinfo[16,4] = [si_hash['x']].pack('L') if si_hash['x']
      startinfo[20,4] = [si_hash['y']].pack('L') if si_hash['y']
      startinfo[24,4] = [si_hash['x_size']].pack('L') if si_hash['x_size']
      startinfo[28,4] = [si_hash['y_size']].pack('L') if si_hash['y_size']
      startinfo[32,4] = [si_hash['x_count_chars']].pack('L') if si_hash['x_count_chars']
      startinfo[36,4] = [si_hash['y_count_chars']].pack('L') if si_hash['y_count_chars']
      startinfo[40,4] = [si_hash['fill_attribute']].pack('L') if si_hash['fill_attribute']
      startinfo[44,4] = [si_hash['startf_flags']].pack('L') if si_hash['startf_flags']
      startinfo[48,2] = [si_hash['sw_flags']].pack('S') if si_hash['sw_flags']
      startinfo[56,4] = [si_hash['stdin']].pack('L') if si_hash['stdin']
      startinfo[60,4] = [si_hash['stdout']].pack('L') if si_hash['stdout']
      startinfo[64,4] = [si_hash['stderr']].pack('L') if si_hash['stderr']        
    end

    if hash['with_logon']
      logon  = multi_to_wide(hash['with_logon'])
      domain = multi_to_wide(hash['domain'])
      app    = hash['app_name'].nil? ? nil : multi_to_wide(hash['app_name'])
      cmd    = hash['command_line'].nil? ? nil : multi_to_wide(hash['command_line'])
      cwd    = multi_to_wide(hash['cwd'])
      passwd = multi_to_wide(hash['password'])
         
      hash['creation_flags'] |= CREATE_UNICODE_ENVIRONMENT

      bool = CreateProcessWithLogonW(
        logon,                  # User
        domain,                 # Domain
        passwd,                 # Password
        LOGON_WITH_PROFILE,     # Logon flags
        app,                    # App name
        cmd,                    # Command line
        hash['creation_flags'], # Creation flags
        env,                    # Environment
        cwd,                    # Working directory
        startinfo,              # Startup Info
        procinfo                # Process Info
      )
    else     
      bool = CreateProcess(
        hash['app_name'],       # App name
        hash['command_line'],   # Command line
        process_security,       # Process attributes
        thread_security,        # Thread attributes
        hash['inherit'],        # Inherit handles?
        hash['creation_flags'], # Creation flags
        env,                    # Environment
        hash['cwd'],            # Working directory
        startinfo,              # Startup Info
        procinfo                # Process Info
      )
    end      
      
    # TODO: Close stdin, stdout and stderr handles in the si_hash unless
    # they're pointing to one of the standard handles already. [Maybe]
    unless bool
      raise Error, "CreateProcess() failed: " + get_last_error
    end
      
    # Automatically close the process and thread handles in the
    # PROCESS_INFORMATION struct unless explicitly told not to.
    if hash['close_handles']
      CloseHandle(procinfo[0,4].unpack('L').first)
      CloseHandle(procinfo[4,4].unpack('L').first)
    end      
      
    ProcessInfo.new(
      procinfo[0,4].unpack('L').first, # hProcess
      procinfo[4,4].unpack('L').first, # hThread
      procinfo[8,4].unpack('L').first, # hProcessId
      procinfo[12,4].unpack('L').first # hThreadId
    )
  end

  module_function :create
end