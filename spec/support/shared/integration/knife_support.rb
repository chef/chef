require 'chef/knife'
require 'chef/application/knife'
require 'logger'
require 'chef/log'

module KnifeSupport
  def knife(*args, &block)
    # Allow knife('role from file roles/blah.json') rather than requiring the
    # arguments to be split like knife('role', 'from', 'file', 'roles/blah.json')
    # If any argument will have actual spaces in it, the long form is required.
    # (Since knife commands always start with the command name, and command
    # names with spaces are always multiple args, this is safe.)
    if args.length == 1
      args = args[0].split(/\s+/)
    end

    # This is Chef::Knife.run without load_commands and load_deps--we'll
    # load stuff ourselves, thank you very much
    stdout = StringIO.new
    stderr = StringIO.new
    old_loggers = Chef::Log.loggers
    old_log_level = Chef::Log.level
    begin
      subcommand_class = Chef::Knife.subcommand_class_from(args)
      subcommand_class.options = Chef::Application::Knife.options.merge(subcommand_class.options)
      instance = subcommand_class.new(args)

      # Capture stdout/stderr
      instance.ui = Chef::Knife::UI.new(stdout, stderr, STDIN, {})

      # Don't print stuff
      Chef::Config[:verbosity] = 0
      instance.configure_chef
      logger = Logger.new(stderr)
      logger.formatter = proc { |severity, datetime, progname, msg| "#{severity}: #{msg}\n" }
      Chef::Log.use_log_devices([logger])
      Chef::Log.level = :warn
      Chef::Log::Formatter.show_time = false
      instance.run

      exit_code = 0

    # This is how rspec catches exit()
    rescue SystemExit => e
      exit_code = e.status
    ensure
      Chef::Log.use_log_devices(old_loggers)
      Chef::Log.level = old_log_level
    end

    KnifeResult.new(stdout.string, stderr.string, exit_code)
  end

  private

  class KnifeResult
    def initialize(stdout, stderr, exit_code)
      @stdout = stdout
      @stderr = stderr
      @exit_code = exit_code
    end

    def should_fail(*args)
      expected = {}
      args.each do |arg|
        if arg.is_a?(Hash)
          expected.merge!(arg)
        elsif arg.is_a?(Integer)
          expected[:exit_code] = arg
        else
          expected[:stderr] = arg
        end
      end
      expected[:exit_code] = 1 if !expected[:exit_code]
      should_result_in(expected)
    end

    def should_succeed(*args)
      expected = {}
      args.each do |arg|
        if arg.is_a?(Hash)
          expected.merge!(arg)
        else
          expected[:stdout] = arg
        end
      end
      should_result_in(expected)
    end

    private

    def should_result_in(expected)
      expected[:stdout] = '' if !expected[:stdout]
      expected[:stderr] = '' if !expected[:stderr]
      expected[:exit_code] = 0 if !expected[:exit_code]
      # TODO make this go away
      stderr_actual = @stderr.sub(/^WARNING: No knife configuration file found\n/, '')

      @stdout.should == expected[:stdout]
      stderr_actual.should == expected[:stderr]
      @exit_code.should == expected[:exit_code]
    end
  end
end
