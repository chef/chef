# Adapted from Autotest::Rails, RSpec's autotest class, as well as merb-core's.
require 'autotest'

class RspecCommandError < StandardError; end

class Autotest::MerbRspec < Autotest

  # +model_tests_dir+::      the directory to find model-centric tests
  # +controller_tests_dir+:: the directory to find controller-centric tests
  # +view_tests_dir+::       the directory to find view-centric tests
  # +fixtures_dir+::         the directory to find fixtures in
  attr_accessor :model_tests_dir, :controller_tests_dir, :view_tests_dir, :fixtures_dir

  def initialize # :nodoc:
    super

    initialize_test_layout

    # Ignore any happenings in these directories
    add_exception %r%^\./(?:doc|log|public|tmp)%

    # Ignore any mappings that Autotest may have already set up
    clear_mappings

    # Any changes to a file in the root of the 'lib' directory will run any
    # model test with a corresponding name.
    add_mapping %r%^lib\/.*\.rb% do |filename, _|
      files_matching %r%#{model_test_for(filename)}$%
    end

    add_mapping %r%^spec/(spec_helper|shared/.*)\.rb$% do
      files_matching %r%^spec/.*_spec\.rb$%
    end

    # Any changes to a fixture will run corresponding view, controller and
    # model tests
    add_mapping %r%^#{fixtures_dir}/(.*)s.yml% do |_, m|
      [
        model_test_for(m[1]),
        controller_test_for(m[1]),
        view_test_for(m[1])
      ]
    end

    # Any change to a test or spec will cause it to be run
    add_mapping %r%^spec/(unit|models|integration|controllers|views|functional)/.*rb$% do |filename, _|
      filename
    end

    # Any change to a model will cause it's corresponding test to be run
    add_mapping %r%^app/models/(.*)\.rb$% do |_, m|
      model_test_for(m[1])
    end

    # Any change to the global helper will result in all view and controller
    # tests being run
    add_mapping %r%^app/helpers/global_helpers.rb% do
      files_matching %r%^spec/(views|functional|controllers)/.*_spec\.rb$%
    end

    # Any change to a helper will run it's corresponding view and controller
    # tests, unless the helper is the global helper. Changes to the global
    # helper run all view and controller tests.
    add_mapping %r%^app/helpers/(.*)_helper(s)?.rb% do |_, m|
      if m[1] == "global" then
        files_matching %r%^spec/(views|functional|controllers)/.*_spec\.rb$%
      else
        [
          view_test_for(m[1]),
          controller_test_for(m[1])
        ]
      end
    end

    # Changes to views result in their corresponding view and controller test
    # being run
    add_mapping %r%^app/views/(.*)/% do |_, m|
      [
        view_test_for(m[1]),
        controller_test_for(m[1])
      ]
    end

    # Changes to a controller result in its corresponding test being run. If
    # the controller is the exception or application controller, all
    # controller tests are run.
    add_mapping %r%^app/controllers/(.*)\.rb$% do |_, m|
      if ["application", "exception"].include?(m[1])
        files_matching %r%^spec/(controllers|views|functional)/.*_spec\.rb$%
      else
        controller_test_for(m[1])
      end
    end

    # If a change is made to the router, run all controller and view tests
    add_mapping %r%^config/router.rb$% do # FIX
      files_matching %r%^spec/(controllers|views|functional)/.*_spec\.rb$%
    end

    # If any of the major files governing the environment are altered, run
    # everything
    add_mapping %r%^spec/spec_helper.rb|config/(init|rack|environments/test.rb|database.yml)% do # FIX
      files_matching %r%^spec/(unit|models|controllers|views|functional)/.*_spec\.rb$%
    end
  end

  def failed_results(results)
    results.scan(/^\d+\)\n(?:\e\[\d*m)?(?:.*?Error in )?'([^\n]*)'(?: FAILED)?(?:\e\[\d*m)?\n(.*?)\n\n/m)
  end

  def handle_results(results)
    @failures = failed_results(results)
    @files_to_test = consolidate_failures @failures
    unless $TESTING
      if @files_to_test.empty?
        hook :green
      else
        hook :red
      end
    end
    @tainted = true unless @files_to_test.empty?
  end

  def consolidate_failures(failed)
    filters = Hash.new { |h,k| h[k] = [] }
    failed.each do |spec, failed_trace|
      find_files.keys.select { |f| f =~ /spec\// }.each do |f|
        if failed_trace =~ Regexp.new(f)
          filters[f] << spec
          break
        end
      end
    end
    filters
  end

  def make_test_cmd(files_to_test)
    [
      ruby,
      "-S",
      spec_command,
      add_options_if_present,
      files_to_test.keys.flatten.join(' ')
    ].join(" ")
  end

  def add_options_if_present
    File.exist?("spec/spec.opts") ? "-O spec/spec.opts " : ""
  end

  # Finds the proper spec command to use. Precendence is set in the
  # lazily-evaluated method spec_commands.  Alias + Override that in
  # ~/.autotest to provide a different spec command then the default
  # paths provided.
  def spec_command(separator=File::ALT_SEPARATOR)
    unless defined? @spec_command then
      @spec_command = spec_commands.find { |cmd| File.exists? cmd }

      raise RspecCommandError, "No spec command could be found!" unless @spec_command

      @spec_command.gsub!(File::SEPARATOR, separator) if separator
    end
    @spec_command
  end

  # Autotest will look for spec commands in the following
  # locations, in this order:
  #
  #   * default spec bin/loader installed in Rubygems
  #   * any spec command found in PATH
  def spec_commands
    [ File.join(Config::CONFIG['bindir'], 'spec'), 'spec' ]
  end

private

  # Determines the paths we can expect tests or specs to reside, as well as
  # corresponding fixtures.
  def initialize_test_layout
    self.model_tests_dir      = "spec/models"
    self.controller_tests_dir = "spec/controllers"
    self.view_tests_dir       = "spec/views"
    self.fixtures_dir         = "spec/fixtures"
  end

  # Given a filename and the test type, this method will return the
  # corresponding test's or spec's name.
  #
  # ==== Arguments
  # +filename+<String>:: the file name of the model, view, or controller
  # +kind_of_test+<Symbol>:: the type of test we that we should run
  #
  # ==== Returns
  # String:: the name of the corresponding test or spec
  #
  # ==== Example
  #
  #   > test_for("user", :model)
  #   => "user_test.rb"
  #   > test_for("login", :controller)
  #   => "login_controller_test.rb"
  #   > test_for("form", :view)
  #   => "form_view_spec.rb" # If you're running a RSpec-like suite
  def test_for(filename, kind_of_test) # :nodoc:
    name  = [filename]
    name << kind_of_test.to_s if kind_of_test == :view
    name << "spec"
    return name.join("_") + ".rb"
  end

  def model_test_for(filename)
    [model_tests_dir, test_for(filename, :model)].join("/")
  end

  def controller_test_for(filename)
    [controller_tests_dir, test_for(filename, :controller)].join("/")
  end

  def view_test_for(filename)
    [view_tests_dir, test_for(filename, :view)].join("/")
  end

end
