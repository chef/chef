require 'spec_helper'

describe Mixlib::ShellOut do
  let(:shell_cmd) { options ? shell_cmd_with_options : shell_cmd_without_options }
  let(:executed_cmd) { shell_cmd.tap(&:run_command) }
  let(:stdout) { executed_cmd.stdout }
  let(:stderr) { executed_cmd.stderr }
  let(:chomped_stdout) { stdout.chomp }
  let(:stripped_stdout) { stdout.strip }
  let(:exit_status) { executed_cmd.status.exitstatus }

  let(:shell_cmd_without_options) { Mixlib::ShellOut.new(cmd) }
  let(:shell_cmd_with_options) { Mixlib::ShellOut.new(cmd, options) }
  let(:cmd) { ruby_eval.call(ruby_code) }
  let(:ruby_code) { raise 'define let(:ruby_code)' }
  let(:options) { nil }

  # On some testing environments, we have gems that creates a deprecation notice sent
  # out on STDERR. To fix that, we disable gems on Ruby 1.9.2
  let(:ruby_eval) { lambda { |code| "ruby #{disable_gems} -e '#{code}'" } }
  let(:disable_gems) { ( ruby_19? ? '--disable-gems' : '') }

  context 'when instantiating' do
    subject { shell_cmd }
    let(:cmd) { 'apt-get install chef' }

    it "should set the command" do
      subject.command.should eql(cmd)
    end

    context 'with default settings' do
      its(:cwd) { should be_nil }
      its(:user) { should be_nil }
      its(:group) { should be_nil }
      its(:umask) { should be_nil }
      its(:timeout) { should eql(600) }
      its(:valid_exit_codes) { should eql([0]) }
      its(:live_stream) { should be_nil }
      its(:input) { should be_nil }

      it "should set default environmental variables" do
        shell_cmd.environment.should == {"LC_ALL" => "C"}
      end
    end

    context 'when setting accessors' do
      subject { shell_cmd.send(accessor) }

      let(:shell_cmd) { blank_shell_cmd.tap(&with_overrides) }
      let(:blank_shell_cmd) { Mixlib::ShellOut.new('apt-get install chef') }
      let(:with_overrides) { lambda { |shell_cmd| shell_cmd.send("#{accessor}=", value) } }

      context 'when setting user' do
        let(:accessor) { :user }
        let(:value) { 'root' }

        it "should set the user" do
          should eql(value)
        end

        context 'with an integer value for user' do
          let(:value) { 0 }
          it "should use the user-supplied uid" do
            shell_cmd.uid.should eql(value)
          end
        end

        context 'with string value for user' do
          let(:value) { username }

          let(:username) { user_info.name }
          let(:expected_uid) { user_info.uid }
          let(:user_info) { Etc.getpwent }

          it "should compute the uid of the user", :unix_only => true do
            shell_cmd.uid.should eql(expected_uid)
          end
        end

      end

      context 'when setting group' do
        let(:accessor) { :group }
        let(:value) { 'wheel' }

        it "should set the group" do
          should eql(value)
        end

        context 'with integer value for group' do
          let(:value) { 0 }
          it "should use the user-supplied gid" do
            shell_cmd.gid.should eql(value)
          end
        end

        context 'with string value for group' do
          let(:value) { groupname }
          let(:groupname) { group_info.name }
          let(:expected_gid) { group_info.gid }
          let(:group_info) { Etc.getgrent }

          it "should compute the gid of the user", :unix_only => true do
            shell_cmd.gid.should eql(expected_gid)
          end
        end
      end

      context 'when setting the umask' do
        let(:accessor) { :umask }

        context 'with octal integer' do
          let(:value) { 007555}

          it 'should set the umask' do
            should eql(value)
          end
        end

        context 'with decimal integer' do
          let(:value) { 2925 }

          it 'should sets the umask' do
            should eql(005555)
          end
        end

        context 'with string' do
          let(:value) { '7777' }

          it 'should sets the umask' do
            should eql(007777)
          end
        end
      end

      context 'when setting read timeout' do
        let(:accessor) { :timeout }
        let(:value) { 10 }

        it 'should set the read timeout' do
          should eql(value)
        end
      end

      context 'when setting valid exit codes' do
        let(:accessor) { :valid_exit_codes }
        let(:value) { [0, 23, 42] }

        it "should set the valid exit codes" do
          should eql(value)
        end
      end

      context 'when setting a live stream' do
        let(:accessor) { :live_stream }
        let(:value) { stream }
        let(:stream) { StringIO.new }

        it "should set the live stream" do
          should eql(value)
        end
      end

      context 'when setting an input' do
        let(:accessor) { :input }
        let(:value) { "Random content #{rand(1000000)}" }

        it "should set the input" do
          should eql(value)
        end
      end
    end

    context "with options hash" do
      let(:cmd) { 'brew install couchdb' }
      let(:options) { { :cwd => cwd, :user => user, :group => group, :umask => umask,
        :timeout => timeout, :environment => environment, :returns => valid_exit_codes,
        :live_stream => stream, :input => input } }

      let(:cwd) { '/tmp' }
      let(:user) { 'toor' }
      let(:group) { 'wheel' }
      let(:umask) { '2222' }
      let(:timeout) { 5 }
      let(:environment) { { 'RUBY_OPTS' => '-w' } }
      let(:valid_exit_codes) { [ 0, 1, 42 ] }
      let(:stream) { StringIO.new }
      let(:input) { 1.upto(10).map { "Data #{rand(100000)}" }.join("\n") }

      it "should set the working directory" do
        shell_cmd.cwd.should eql(cwd)
      end

      it "should set the user" do
        shell_cmd.user.should eql(user)
      end

      it "should set the group" do
        shell_cmd.group.should eql(group)
      end

      it "should set the umask" do
        shell_cmd.umask.should eql(002222)
      end

      it "should set the timout" do
        shell_cmd.timeout.should eql(timeout)
      end

      it "should add environment settings to the default" do
        shell_cmd.environment.should eql({'LC_ALL' => 'C', 'RUBY_OPTS' => '-w'})
      end

      context 'when setting custom environments' do
        context 'when setting the :env option' do
          let(:options) { { :env => environment } }

          it "should also set the enviroment" do
            shell_cmd.environment.should eql({'LC_ALL' => 'C', 'RUBY_OPTS' => '-w'})
          end
        end

        context 'when :environment is set to nil' do
          let(:options) { { :environment => nil } }

          it "should not set any environment" do
            shell_cmd.environment.should == {}
          end
        end

        context 'when :env is set to nil' do
          let(:options) { { :env => nil } }

          it "should not set any environment" do
            shell_cmd.environment.should eql({})
          end
        end
      end

      it "should set valid exit codes" do
        shell_cmd.valid_exit_codes.should eql(valid_exit_codes)
      end

      it "should set the live stream" do
        shell_cmd.live_stream.should eql(stream)
      end

      it "should set the input" do
        shell_cmd.input.should eql(input)
      end

      context 'with an invalid option' do
        let(:options) { { :frab => :job } }
        let(:invalid_option_exception) { Mixlib::ShellOut::InvalidCommandOption }
        let(:exception_message) { "option ':frab' is not a valid option for Mixlib::ShellOut" }

        it "should raise InvalidCommandOPtion" do
          lambda { shell_cmd }.should raise_error(invalid_option_exception, exception_message)
        end
      end
    end

    context "with array of command and args" do
      let(:cmd) { [ 'ruby', '-e', %q{'puts "hello"'} ] }

      context 'without options' do
        let(:options) { nil }

        it "should set the command to the array of command and args" do
          shell_cmd.command.should eql(cmd)
        end
      end

      context 'with options' do
        let(:options) { {:cwd => '/tmp', :user => 'nobody'} }

        it "should set the command to the array of command and args" do
          shell_cmd.command.should eql(cmd)
        end

        it "should evaluate the options" do
          shell_cmd.cwd.should eql('/tmp')
          shell_cmd.user.should eql('nobody')
        end
      end
    end
  end

  context 'when executing the command' do
    let(:dir) { Dir.mktmpdir }
    let(:dump_file) { "#{dir}/out.txt" }
    let(:dump_file_content) { stdout; IO.read(dump_file) }

    context 'with a current working directory' do
      subject { File.expand_path(chomped_stdout) }
      let(:fully_qualified_cwd) { File.expand_path(cwd) }
      let(:options) { { :cwd => cwd } }

      context 'when running under Unix', :unix_only => true do
        let(:cwd) { '/bin' }
        let(:cmd) { 'pwd' }

        it "should chdir to the working directory" do
          should eql(fully_qualified_cwd)
        end
      end

      context 'when running under Windows', :windows_only => true do
        let(:cwd) { Dir.tmpdir }
        let(:cmd) { 'echo %cd%' }

        it "should chdir to the working directory" do
          should eql(fully_qualified_cwd)
        end
      end
    end

    context 'when handling locale' do
      subject { stripped_stdout }
      let(:cmd) { ECHO_LC_ALL }
      let(:options) { { :environment => { 'LC_ALL' => locale } } }

      context 'without specifying environment' do
        let(:options) { nil }
        it "should use the C locale by default" do
          should eql('C')
        end
      end

      context 'with locale' do
        let(:locale) { 'es' }

        it "should use the requested locale" do
          should eql(locale)
        end
      end

      context 'with LC_ALL set to nil' do
        let(:locale) { nil }

        context 'when running under Unix', :unix_only => true do
          let(:parent_locale) { ENV['LC_ALL'].to_s.strip }

          it "should use the parent process's locale" do
            should eql(parent_locale)
          end
        end

        context 'when running under Windows', :windows_only => true do
          # On windows, if an environmental variable is not set, it returns the key
          let(:parent_locale) { (ENV['LC_ALL'] || '%LC_ALL%').to_s.strip }

          it "should use the parent process's locale" do
            should eql(parent_locale)
          end
        end
      end
    end

    context "with a live stream" do
      let(:stream) { StringIO.new }
      let(:ruby_code) { 'puts "hello"' }
      let(:options) { { :live_stream => stream } }

      it "should copy the child's stdout to the live stream" do
        shell_cmd.run_command
        stream.string.should eql("hello#{LINE_ENDING}")
      end
    end

    context "with an input" do
      subject { stdout }

      let(:input) { 'hello' }
      let(:ruby_code) { 'STDIN.sync = true; STDOUT.sync = true; puts gets' }
      let(:options) { { :input => input } }

      it "should copy the input to the child's stdin" do
        should eql("hello#{LINE_ENDING}")
      end
    end

    context "when running different types of command" do
      let(:script) { open_file.tap(&write_file).tap(&:close).tap(&make_executable) }
      let(:file_name) { "#{dir}/Setup Script.cmd" }
      let(:script_name) { "\"#{script.path}\"" }

      let(:open_file) { File.open(file_name, 'w') }
      let(:write_file) { lambda { |f| f.write(script_content) } }
      let(:make_executable) { lambda { |f| File.chmod(0755, f.path) } }

      context 'with spaces in the path' do
        subject { chomped_stdout }
        let(:cmd) { script_name }


        context 'when running under Unix', :unix_only => true do
          let(:script_content) { 'echo blah' }

          it 'should execute' do
            should eql('blah')
          end
        end

        context 'when running under Windows', :windows_only => true do
          let(:cmd) { "#{script_name} #{argument}" }
          let(:script_content) { '@echo %1' }
          let(:argument) { rand(10000).to_s }

          it 'should execute' do
            should eql(argument)
          end

          context 'with multiple quotes in the command and args' do
            context 'when using a batch file' do
              let(:argument) { "\"Random #{rand(10000)}\"" }

              it 'should execute' do
                should eql(argument)
              end
            end

            context 'when not using a batch file' do
              let(:watch) { lambda { |a| ap a } }
              let(:cmd) { "#{executable_file_name} #{script_name}" }

              let(:executable_file_name) { "\"#{dir}/Ruby Parser.exe\"".tap(&make_executable!) }
              let(:make_executable!) { lambda { |filename| Mixlib::ShellOut.new("copy \"#{full_path_to_ruby}\" #{filename}").run_command } }
              let(:script_content) { "print \"#{expected_output}\"" }
              let(:expected_output) { "Random #{rand(10000)}" }

              let(:full_path_to_ruby) { ENV['PATH'].split(';').map(&try_ruby).reject(&:nil?).first }
              let(:try_ruby) { lambda { |path| "#{path}\\ruby.exe" if File.executable? "#{path}\\ruby.exe" } }

              it 'should execute' do
                should eql(expected_output)
              end
            end
          end
        end
      end


      context 'with lots of long arguments' do
        subject { chomped_stdout }

        # This number was chosen because it seems to be an actual maximum
        # in Windows--somewhere around 6-7K of command line
        let(:echotext) { 10000.upto(11340).map(&:to_s).join(' ') }
        let(:cmd) { "echo #{echotext}" }

        it 'should execute' do
          should eql(echotext)
        end
      end

      context 'with special characters' do
        subject { stdout }

        let(:special_characters) { '<>&|&&||;' }
        let(:ruby_code) { "print \"#{special_characters}\"" }

        it 'should execute' do
          should eql(special_characters)
        end
      end


      context 'with backslashes' do
        subject { stdout }
        let(:backslashes) { %q{\\"\\\\} }
        let(:cmd) { ruby_eval.call("print \"#{backslashes}\"") }

        it 'should execute' do
          should eql("\"\\")
        end
      end

      context 'with pipes' do
        let(:input_script) { "STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false" }
        let(:output_script) { "print STDIN.read.length" }
        let(:cmd) { ruby_eval.call(input_script) + " | " + ruby_eval.call(output_script) }

        it 'should execute' do
          stdout.should eql('4')
        end

        it 'should handle stderr' do
          stderr.should eql('false')
        end
      end

      context 'with stdout and stderr file pipes' do
        let(:code) { "STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false" }
        let(:cmd) { ruby_eval.call(code) + " > #{dump_file}" }

        it 'should execute' do
          stdout.should eql('')
        end

        it 'should handle stderr' do
          stderr.should eql('false')
        end

        it 'should write to file pipe' do
          dump_file_content.should eql('true')
        end
      end

      context 'with stdin file pipe' do
        let(:code) { "STDIN.sync = true; STDOUT.sync = true; STDERR.sync = true; print gets; STDERR.print false" }
        let(:cmd) { ruby_eval.call(code) + " < #{dump_file_path}" }
        let(:file_content) { "Random content #{rand(100000)}" }

        let(:dump_file_path) { dump_file.path }
        let(:dump_file) { open_file.tap(&write_file).tap(&:close) }
        let(:file_name) { "#{dir}/input" }

        let(:open_file) { File.open(file_name, 'w') }
        let(:write_file) { lambda { |f| f.write(file_content) } }

        it 'should execute' do
          stdout.should eql(file_content)
        end

        it 'should handle stderr' do
          stderr.should eql('false')
        end
      end

      context 'with stdout and stderr file pipes' do
        let(:code) { "STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false" }
        let(:cmd) { ruby_eval.call(code) + " > #{dump_file} 2>&1" }

        it 'should execute' do
          stdout.should eql('')
        end

        it 'should write to file pipe' do
          dump_file_content.should eql('truefalse')
        end
      end

      context 'with &&' do
        subject { stdout }
        let(:cmd) { ruby_eval.call('print "foo"') + ' && ' + ruby_eval.call('print "bar"') }

        it 'should execute' do
          should eql('foobar')
        end
      end

      context 'with ||' do
        let(:cmd) { ruby_eval.call('print "foo"; exit 1') + ' || ' + ruby_eval.call('print "bar"') }

        it 'should execute' do
          stdout.should eql('foobar')
        end

        it 'should exit with code 0' do
          exit_status.should eql(0)
        end
      end
    end

    context "when handling process exit codes" do
      let(:cmd) { ruby_eval.call("exit #{exit_code}") }

      context 'with normal exit status' do
        let(:exit_code) { 0 }

        it "should not raise error" do
          lambda { executed_cmd.error! }.should_not raise_error
        end

        it "should set the exit status of the command" do
          exit_status.should eql(exit_code)
        end
      end

      context 'with nonzero exit status' do
        let(:exit_code) { 2 }
        let(:exception_message_format) { Regexp.escape(executed_cmd.format_for_exception) }

        it "should raise ShellCommandFailed" do
          lambda { executed_cmd.error! }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
        end

        it "includes output with exceptions from #error!" do
          begin
            executed_cmd.error!
          rescue Mixlib::ShellOut::ShellCommandFailed => e
            e.message.should match(exception_message_format)
          end
        end

        it "should set the exit status of the command" do
          exit_status.should eql(exit_code)
        end
      end

      context 'with valid exit codes' do
        let(:cmd) { ruby_eval.call("exit #{exit_code}" ) }
        let(:options) { { :returns => valid_exit_codes } }

        context 'when exiting with valid code' do
          let(:valid_exit_codes) { 42 }
          let(:exit_code) { 42 }

          it "should not raise error" do
            lambda { executed_cmd.error! }.should_not raise_error
          end

          it "should set the exit status of the command" do
            exit_status.should eql(exit_code)
          end
        end

        context 'when exiting with invalid code' do
          let(:valid_exit_codes) { [ 0, 1, 42 ] }
          let(:exit_code) { 2 }

          it "should raise ShellCommandFailed" do
            lambda { executed_cmd.error! }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
          end

          it "should set the exit status of the command" do
            exit_status.should eql(exit_code)
          end

          context 'with input data' do
            let(:options) { { :returns => valid_exit_codes, :input => input } }
            let(:input) { "Random data #{rand(1000000)}" }

            it "should raise ShellCommandFailed" do
              lambda { executed_cmd.error! }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
            end

            it "should set the exit status of the command" do
              exit_status.should eql(exit_code)
            end
          end
        end

        context 'when exiting with invalid code 0' do
          let(:valid_exit_codes) { 42 }
          let(:exit_code) { 0 }

          it "should raise ShellCommandFailed" do
            lambda { executed_cmd.error! }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
          end

          it "should set the exit status of the command" do
            exit_status.should eql(exit_code)
          end
        end
      end

      describe "#invalid!" do
        let(:exit_code) { 0 }

        it "should raise ShellCommandFailed" do
          lambda { executed_cmd.invalid!("I expected this to exit 42, not 0") }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
        end
      end
    end

    context "when handling the subprocess" do
      context 'with STDOUT and STDERR' do
        let(:ruby_code) { 'STDERR.puts :hello; STDOUT.puts :world' }

        # We could separate this into two examples, but we want to make
        # sure that stderr and stdout gets collected without stepping
        # on each other.
        it "should collect all of STDOUT and STDERR" do
          stderr.should eql("hello#{LINE_ENDING}")
          stdout.should eql("world#{LINE_ENDING}")
        end
      end

      context 'with forking subprocess that does not close stdout and stderr' do
        let(:ruby_code) { "exit if fork; 10.times { sleep 1 }" }

        it "should not hang" do
          proc do
            Timeout.timeout(2) do
              executed_cmd
            end
          end.should_not raise_error
        end
      end

      context 'with subprocess that takes longer than timeout' do
        let(:cmd) { ruby_eval.call('sleep 2') }
        let(:options) { { :timeout => 0.1 } }

        it "should raise CommandTimeout" do
          lambda { executed_cmd }.should raise_error(Mixlib::ShellOut::CommandTimeout)
        end
      end

      context 'with subprocess that exceeds buffersize' do
        let(:ruby_code) { 'print("X" * 16 * 1024); print("." * 1024)' }

        it "should still reads all of the output" do
          stdout.should match(/X{16384}\.{1024}/)
        end
      end

      context 'with subprocess that returns nothing' do
        let(:ruby_code) { 'exit 0' }

        it 'should return an empty string for stdout' do
          stdout.should eql('')
        end

        it 'should return an empty string for stderr' do
          stderr.should eql('')
        end
      end

      context 'with subprocess that closes stdin and continues writing to stdout' do
        let(:ruby_code) { "STDIN.close; sleep 0.5; STDOUT.puts :win" }
        let(:options) { { :input => "Random data #{rand(100000)}" } }

        it 'should not hang or lose outupt' do
          stdout.should eql("win#{LINE_ENDING}")
        end
      end

      context 'with subprocess that closes stdout and continues writing to stderr' do
        let(:ruby_code) { "STDOUT.close; sleep 0.5; STDERR.puts :win" }

        it 'should not hang or lose outupt' do
          stderr.should eql("win#{LINE_ENDING}")
        end
      end

      context 'with subprocess that closes stderr and continues writing to stdout' do
        let(:ruby_code) { "STDERR.close; sleep 0.5; STDOUT.puts :win" }

        it 'should not hang or lose outupt' do
          stdout.should eql("win#{LINE_ENDING}")
        end
      end

      # Regression test:
      #
      # We need to ensure that stderr is removed from the list of file
      # descriptors that we attempt to select() on in the case that:
      #
      # a) STDOUT closes first
      # b) STDERR closes
      # c) The program does not exit for some time after (b) occurs.
      #
      # Otherwise, we will attempt to read from the closed STDOUT pipe over and
      # over again and generate lots of garbage, which will not be collected
      # since we have to turn GC off to avoid segv.
      context 'with subprocess that closes STDOUT before closing STDERR' do
        let(:ruby_code) {  %q{STDOUT.puts "F" * 4096; STDOUT.close; sleep 0.1; STDERR.puts "foo"; STDERR.close; sleep 0.1; exit} }
        let(:unclosed_pipes) { executed_cmd.send(:open_pipes) }

        it 'should not hang' do
          stdout.should_not be_empty
        end

        it 'should close all pipes', :unix_only => true do
          unclosed_pipes.should be_empty
        end
      end

      context 'with subprocess reading lots of data from stdin' do
        subject { stdout.to_i }
        let(:ruby_code) { 'STDOUT.print gets.size' }
        let(:options) { { :input => input } }
        let(:input) { 'f' * 20_000 }
        let(:input_size) { input.size }

        it 'should not hang' do
          should eql(input_size)
        end
      end

      context 'with subprocess writing lots of data to both stdout and stderr' do
        let(:expected_output_with) { lambda { |chr| (chr * 20_000) + "#{LINE_ENDING}" + (chr * 20_000) + "#{LINE_ENDING}" } }

        context 'when writing to STDOUT first' do
          let(:ruby_code) { %q{puts "f" * 20_000; STDERR.puts "u" * 20_000; puts "f" * 20_000; STDERR.puts "u" * 20_000} }

          it "should not deadlock" do
            stdout.should eql(expected_output_with.call('f'))
            stderr.should eql(expected_output_with.call('u'))
          end
        end

        context 'when writing to STDERR first' do
          let(:ruby_code) { %q{STDERR.puts "u" * 20_000; puts "f" * 20_000; STDERR.puts "u" * 20_000; puts "f" * 20_000} }

          it "should not deadlock" do
            stdout.should eql(expected_output_with.call('f'))
            stderr.should eql(expected_output_with.call('u'))
          end
        end
      end

      context 'with subprocess piping lots of data through stdin, stdout, and stderr' do
        let(:multiplier) { 20 }
        let(:expected_output_with) { lambda { |chr| (chr * multiplier) + (chr * multiplier) } }

        # Use regex to work across Ruby versions
        let(:ruby_code) { "STDOUT.sync = STDERR.sync = true; while(input = gets) do ( input =~ /^f/ ? STDOUT : STDERR ).print input.chomp; end" }

        let(:options) { { :input => input } }

        context 'when writing to STDOUT first' do
          let(:input) { [ 'f' * multiplier, 'u' * multiplier, 'f' * multiplier, 'u' * multiplier ].join(LINE_ENDING) }

          it "should not deadlock" do
            stdout.should eql(expected_output_with.call('f'))
            stderr.should eql(expected_output_with.call('u'))
          end
        end

        context 'when writing to STDERR first' do
          let(:input) { [ 'u' * multiplier, 'f' * multiplier, 'u' * multiplier, 'f' * multiplier ].join(LINE_ENDING) }

          it "should not deadlock" do
            stdout.should eql(expected_output_with.call('f'))
            stderr.should eql(expected_output_with.call('u'))
          end
        end
      end

      context 'when subprocess closes prematurely', :unix_only => true do
        context 'with input data' do
          let(:ruby_code) { 'bad_ruby { [ } ]' }
          let(:options) { { :input => input } }
          let(:input) { [ 'f' * 20_000, 'u' * 20_000, 'f' * 20_000, 'u' * 20_000 ].join(LINE_ENDING) }

          # Should the exception be handled?
          it 'should raise error' do
            lambda { executed_cmd }.should raise_error(Errno::EPIPE)
          end
        end
      end

      context 'when subprocess writes, pauses, then continues writing' do
        subject { stdout }
        let(:ruby_code) { %q{puts "before"; sleep 0.5; puts "after"} }

        it 'should not hang or lose output' do
          should eql("before#{LINE_ENDING}after#{LINE_ENDING}")
        end
      end

      context 'when subprocess pauses before writing' do
        subject { stdout }
        let(:ruby_code) { 'sleep 0.5; puts "missed_the_bus"' }

        it 'should not hang or lose output' do
          should eql("missed_the_bus#{LINE_ENDING}")
        end
      end

      context 'when subprocess pauses before reading from stdin' do
        subject { stdout.to_i }
        let(:ruby_code) { 'sleep 0.5; print gets.size ' }
        let(:input) { 'c' * 1024 }
        let(:input_size) { input.size }
        let(:options) { { :input => input } }

        it 'should not hang or lose output' do
          should eql(input_size)
        end
      end

      context 'when execution fails' do
        let(:cmd) { "fuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu" }

        context 'when running under Unix', :unix_only => true do
          it "should recover the error message" do
            lambda { executed_cmd }.should raise_error(Errno::ENOENT)
          end

          context 'with input' do
            let(:options) { {:input => input } }
            let(:input) { "Random input #{rand(1000000)}" }

            it "should recover the error message" do
              lambda { executed_cmd }.should raise_error(Errno::ENOENT)
            end
          end
        end

        pending 'when running under Windows', :windows_only => true
      end

      context 'without input data' do
        context 'with subprocess that expects stdin' do
          let(:ruby_code) { %q{print STDIN.eof?.to_s} }

          # If we don't have anything to send to the subprocess, we need to close
          # stdin so that the subprocess won't wait for input.
          it 'should close stdin' do
            stdout.should eql("true")
          end
        end
      end
    end

    describe "#format_for_exception" do
      let(:ruby_code) { %q{STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"} }
      let(:exception_output) { executed_cmd.format_for_exception.split("\n") }
      let(:expected_output) { [
        "---- Begin output of #{cmd} ----",
        %q{STDOUT: msg_in_stdout},
        %q{STDERR: msg_in_stderr},
        "---- End output of #{cmd} ----",
        "Ran #{cmd} returned 0"
      ] }

      it "should format exception messages" do
        exception_output.each_with_index do |output_line, i|
          output_line.should eql(expected_output[i])
        end
      end
    end
  end
end
