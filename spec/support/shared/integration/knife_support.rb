require 'chef/knife'
require 'chef/application/knife'

module KnifeSupport
  def knife(*args, &block)
    result = KnifeRunner.new
    result.run(*args, &block)
    result
  end

  private

  class KnifeRunner
    def stdout
      @stdout.string
    end

    def stderr
      @stderr.string
    end

    def exit_code
      @exit_code
    end

    def run(*args, &block)
      # This is Chef::Knife.run without load_commands and load_deps--we'll
      # load stuff ourselves, thank you very much
      @stdout = StringIO.new
      @stderr = StringIO.new
      begin
        subcommand_class = Chef::Knife.subcommand_class_from(args)
        subcommand_class.options = Chef::Application::Knife.options.merge(subcommand_class.options)
        instance = subcommand_class.new(args)

        # Capture stdout/stderr
        instance.ui = Chef::Knife::UI.new(@stdout, @stderr, STDIN, {})

        # Don't print stuff
        Chef::Config[:verbosity] = 0
        instance.configure_chef
        @exit_code = instance.run
      rescue SystemExit => e
        @exit_code = e.status
      end

      instance_eval(&block) if block
    end
  end
end
