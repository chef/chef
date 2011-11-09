#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'etc'
require 'tmpdir'
require 'chef/log'
require 'fcntl'
require 'chef/exceptions'

class Chef

  # == Chef::ShellOut
  # Provides a simplified interface to shelling out yet still collecting both
  # standard out and standard error and providing full control over environment,
  # working directory, uid, gid, etc.
  #
  # No means for passing input to the subprocess is provided, nor is there any
  # way to inspect the output of the command as it is being read. If you need
  # to do that, you have to use popen4 (in Chef::Mixin::Command)
  #
  # === Platform Support
  # Chef::ShellOut uses Kernel.fork() and is therefore unsuitable for Windows
  # or jruby.
  class ShellOut
    READ_WAIT_TIME = 0.01
    READ_SIZE = 4096
    DEFAULT_READ_TIMEOUT = 600
    DEFAULT_ENVIRONMENT = {'LC_ALL' => 'C'}

    if RUBY_PLATFORM =~ /mswin|mingw32|windows/
      require 'chef/shell_out/windows'
      include ShellOut::Windows
    else
      require 'chef/shell_out/unix'
      include ShellOut::Unix
    end

    attr_accessor :user
    attr_accessor :group
    attr_accessor :cwd
    attr_accessor :valid_exit_codes
    attr_accessor :live_stream
    attr_accessor :command_log_level
    attr_accessor :command_log_prepend

    attr_reader :command, :umask, :environment
    attr_writer :timeout
    attr_reader :execution_time

    attr_reader :stdout, :stderr, :status

    attr_reader :stdin_pipe, :stdout_pipe, :stderr_pipe, :process_status_pipe

    # === Arguments:
    # Takes a single command, or a list of command fragments. These are used
    # as arguments to Kernel.exec. See the Kernel.exec documentation for more
    # explanation of how arguments are evaluated. The last argument can be an
    # options Hash.
    # === Options:
    # If the last argument is a Hash, it is removed from the list of args passed
    # to exec and used as an options hash. The following options are available:
    # * +user+: the user the commmand should run as. if an integer is given, it is
    #   used as a uid. A string is treated as a username and resolved to a uid
    #   with Etc.getpwnam
    # * +group+: the group the command should run as. works similarly to +user+
    # * +cwd+: the directory to chdir to before running the command
    # * +umask+: a umask to set before running the command. If given as an Integer,
    #   be sure to use two leading zeros so it's parsed as Octal. A string will
    #   be treated as an octal integer
    # * +returns+:  one or more Integer values to use as valid exit codes for the
    #   subprocess. This only has an effect if you call +error!+ after
    #   +run_command+.
    # * +environment+: a Hash of environment variables to set before the command
    #   is run. By default, the environment will *always* be set to 'LC_ALL' => 'C'
    #   to prevent issues with multibyte characters in Ruby 1.8. To avoid this,
    #   use :environment => nil for *no* extra environment settings, or
    #   :environment => {'LC_ALL'=>nil, ...} to set other environment settings
    #   without changing the locale.
    # * +timeout+: a Numeric value for the number of seconds to wait on the
    #   child process before raising an Exception. This is calculated as the
    #   total amount of time that ShellOut waited on the child process without
    #   receiving any output (i.e., IO.select returned nil). Default is 60
    #   seconds. Note: the stdlib Timeout library is not used.
    # === Examples:
    # Invoke find(1) to search for .rb files:
    #   find = Chef::ShellOut.new("find . -name '*.rb'")
    #   find.run_command
    #   # If all went well, the results are on +stdout+
    #   puts find.stdout
    #   # find(1) prints diagnostic info to STDERR:
    #   puts "error messages" + find.stderr
    #   # Raise an exception if it didn't exit with 0
    #   find.error!
    # Run a command as the +www+ user with no extra ENV settings from +/tmp+
    #   cmd = Chef::ShellOut.new("apachectl", "start", :user => 'www', :env => nil, :cwd => '/tmp')
    #   cmd.run_command # etc.
    def initialize(*command_args)
      @stdout, @stderr = '', ''
      @live_stream = nil
      @command_log_level = :debug
      @command_log_prepend = nil
      @environment = DEFAULT_ENVIRONMENT
      @cwd = nil
      @valid_exit_codes = [0]

      if command_args.last.is_a?(Hash)
        parse_options(command_args.pop)
      end

      @command = command_args.size == 1 ? command_args.first : command_args
    end

    def umask=(new_umask)
      @umask = (new_umask.respond_to?(:oct) ? new_umask.oct : new_umask.to_i) & 007777
    end

    def uid
      return nil unless user
      user.kind_of?(Integer) ? user : Etc.getpwnam(user.to_s).uid
    end

    def gid
      return nil unless group
      group.kind_of?(Integer) ? group : Etc.getgrnam(group.to_s).gid
    end

    def timeout
      @timeout || DEFAULT_READ_TIMEOUT
    end

    # Creates a String showing the output of the command, including a banner
    # showing the exact command executed. Used by +invalid!+ to show command
    # results when the command exited with an unexpected status.
    def format_for_exception
      msg = ""
      msg << "---- Begin output of #{command} ----\n"
      msg << "STDOUT: #{stdout.strip}\n"
      msg << "STDERR: #{stderr.strip}\n"
      msg << "---- End output of #{command} ----\n"
      msg << "Ran #{command} returned #{status.exitstatus}" if status
      msg
    end

    def exitstatus
      @status && @status.exitstatus
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
    #   within +timeout+ seconds (default: 60s)
    def run_command
      if command_log_prepend
        Chef::Log.send(command_log_level, "#{command_log_prepend} sh(#{@command})")
      else
        Chef::Log.send(command_log_level, "sh(#{@command})")
      end
      super
    end

    # Checks the +exitstatus+ against the set of +valid_exit_codes+. If
    # +exitstatus+ is not in the list of +valid_exit_codes+, calls +invalid!+,
    # which raises an Exception.
    # === Returns
    # nil::: always returns nil when it does not raise
    # === Raises
    # Chef::Exceptions::ShellCommandFailed::: via +invalid!+
    def error!
      unless Array(valid_exit_codes).include?(exitstatus)
        invalid!("Expected process to exit with #{valid_exit_codes.inspect}, but received '#{exitstatus}'")
      end
    end

    # Raises a Chef::Exceptions::ShellCommandFailed exception, appending the
    # command's stdout, stderr, and exitstatus to the exception message.
    # === Arguments
    # +msg+:  A String to use as the basis of the exception message. The
    # default explanation is very generic, providing a more informative message
    # is highly encouraged.
    # === Raises
    # Chef::Exceptions::ShellCommandFailed  always
    def invalid!(msg=nil)
      msg ||= "Command produced unexpected results"
      raise Chef::Exceptions::ShellCommandFailed, msg + "\n" + format_for_exception
    end

    def inspect
      "<#{self.class.name}##{object_id}: command: '#@command' process_status: #{@status.inspect} " +
      "stdout: '#{stdout.strip}' stderr: '#{stderr.strip}' child_pid: #{@child_pid.inspect} " +
      "environment: #{@environment.inspect} timeout: #{timeout} user: #@user group: #@group working_dir: #@cwd >"
    end

    private

    def parse_options(opts)
      opts.each do |option, setting|
        case option.to_s
        when 'cwd'
          self.cwd = setting
        when 'user'
          self.user = setting
        when 'group'
          self.group = setting
        when 'umask'
          self.umask = setting
        when 'timeout'
          self.timeout = setting
        when 'returns'
          self.valid_exit_codes = Array(setting)
        when 'live_stream'
          self.live_stream = setting
        when 'command_log_level'
          self.command_log_level = setting
        when 'command_log_prepend'
          self.command_log_prepend = setting
        when 'environment', 'env'
          # passing :environment => nil means don't set any new ENV vars
          @environment = setting.nil? ? {} : @environment.dup.merge!(setting)
        else
          raise Chef::Exceptions::InvalidCommandOption, "option '#{option.inspect}' is not a valid option for #{self.class.name}"
        end
      end
    end


  end
end
