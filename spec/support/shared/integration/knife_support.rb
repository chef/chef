require 'chef/knife'
require 'chef/application/knife'

module KnifeSupport
  def knife(*args)
    result = KnifeRunner.new
    result.run(*args)
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

    def run(*args)
      # This is Chef::Knife.run without load_commands and load_deps--we'll
      # load stuff ourselves, thank you very much
      subcommand_class = Chef::Knife.subcommand_class_from(args)
      subcommand_class.options = Chef::Application::Knife.options.merge(subcommand_class.options)
      instance = subcommand_class.new(args)

      # Capture stdout/stderr
      @stdout = StringIO.new
      @stderr = StringIO.new
      instance.ui = Chef::Knife::UI.new(@stdout, @stderr, STDIN, {})

      # Don't print stuff
      Chef::Config[:verbosity] = 0
      instance.configure_chef
      instance.run
    end
  end
end
