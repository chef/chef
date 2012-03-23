require 'spec_helper'

describe Mixlib::ShellOut do
  subject { shell_cmd }
  let(:shell_cmd) { Mixlib::ShellOut.new('apt-get install chef') }

  context 'when instantiating' do
    it "should set the command" do
      subject.command.should eql("apt-get install chef")
    end

    context 'with default settings' do
      its(:cwd) { should be_nil }
      its(:user) { should be_nil }
      its(:group) { should be_nil }
      its(:umask) { should be_nil }
      its(:timeout) { should eql(600) }
      its(:valid_exit_codes) { should eql([0]) }
      its(:live_stream) { should be_nil }

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
    end

    context "with options hash" do
      let(:shell_cmd) { Mixlib::ShellOut.new("brew install couchdb", options) }
      let(:options) { { :cwd => cwd, :user => user, :group => group, :umask => umask,
        :timeout => timeout, :environment => environment, :returns => valid_exit_codes, :live_stream => stream } }

      let(:cwd) { '/tmp' }
      let(:user) { 'toor' }
      let(:group) { 'wheel' }
      let(:umask) { '2222' }
      let(:timeout) { 5 }
      let(:environment) { { 'RUBY_OPTS' => '-w' } }
      let(:valid_exit_codes) { [ 0, 1, 42 ] }
      let(:stream) { StringIO.new }

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
      context 'without options' do
        let(:shell_cmd) { Mixlib::ShellOut.new('ruby', '-e', %q{'puts "hello"'}) }

        it "should set the command to the array of command and args" do
          shell_cmd.command.should eql(['ruby', '-e', %q{'puts "hello"'}])
        end
      end

      context 'with options' do
        let(:shell_cmd) { Mixlib::ShellOut.new('ruby', '-e', %q{'puts "hello"'}, options) }
        let(:options) { {:cwd => '/tmp', :user => 'nobody'} }

        it "should set the command to the array of command and args" do
          shell_cmd.command.should eql(['ruby', '-e', %q{'puts "hello"'}])
        end

        it "should evaluate the options" do
          shell_cmd.cwd.should == '/tmp'
          shell_cmd.user.should == 'nobody'
        end
      end
    end
  end

  context 'when executing the command' do
    let(:shell_cmd) { Mixlib::ShellOut.new(cmd) }
    let(:executed_cmd) { shell_cmd.tap(&:run_command) }
    let(:stdout) { executed_cmd.stdout }
    let(:stderr) { executed_cmd.stderr }
    let(:chomped_stdout) { stdout.chomp }

    let(:dir) { Dir.mktmpdir }
    let(:ruby_eval) { lambda { |code| "ruby -e '#{code}'" } }
    let(:dump_file) { "#{dir}/out.txt" }
    let(:dump_file_content) { stdout; IO.read(dump_file) }

    context 'with a current working directory' do
      subject { File.expand_path(chomped_stdout) }
      let(:fully_qualified_cwd) { File.expand_path(cwd) }
      let(:shell_cmd) { Mixlib::ShellOut.new(cmd, :cwd => cwd) }

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

    context "with a live stream" do
      let(:stream) { StringIO.new }
      let(:shell_cmd) { Mixlib::ShellOut.new(%q{ruby -e 'puts "hello"'}, :live_stream => stream) }

      it "should copy the child's stdout to the live stream" do
        shell_cmd.run_command
        stream.string.should eql("hello#{LINE_ENDING}")
      end
    end

    context "when running different types of command" do
      context 'with spaces in the path' do
        subject { chomped_stdout }
        let(:shell_cmd) { Mixlib::ShellOut.new(script_name) }

        let(:script) { open_file.tap(&write_file).tap(&:close).tap(&make_executable) }
        let(:file_name) { "#{dir}/blah blah.cmd" }
        let(:script_name) { "\"#{script.path}\"" }

        let(:open_file) { File.open(file_name, 'w') }
        let(:write_file) { lambda { |f| f.write(script_content) } }
        let(:make_executable) { lambda { |f| File.chmod(0755, f.path) } }

        context 'when running under Unix', :unix_only => true do
          let(:script_content) { 'echo blah' }

          it 'should execute' do
            should eql('blah')
          end
        end

        context 'when running under Windows', :windows_only => true do
          let(:script_content) { '@echo blah' }

          it 'should execute' do
            should eql('blah')
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
        let(:cmd) { "ruby -e 'print \"#{special_characters}\"'" }

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

      context 'with file pipes' do
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
        let(:exit_status) { executed_cmd.status.exitstatus }
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

      context 'with nonzero exit status' do
        let(:exit_code) { 2 }

        it "should raise InvalidCommandResult" do
          lambda { executed_cmd.error! }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
        end
      end

      context 'with valid exit codes' do
        let(:shell_cmd) { Mixlib::ShellOut.new(cmd, :returns => valid_exit_codes) }
        let(:cmd) { ruby_eval.call("exit #{exit_code}" ) }

        context 'when exiting with valid code' do
          let(:valid_exit_codes) { 42 }
          let(:exit_code) { 42 }

          it "should raise InvalidCommandResult" do
            lambda { executed_cmd.error! }.should_not raise_error
          end
        end

        context 'when exiting with invalid code' do
          let(:valid_exit_codes) { [ 0, 1, 42 ] }
          let(:exit_code) { 2 }
          it "should raise InvalidCommandResult" do
            lambda { executed_cmd.error! }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
          end
        end

        context 'when exiting with invalid code 0' do
          let(:valid_exit_codes) { 42 }
          let(:exit_code) { 0 }

          it "should raise InvalidCommandResult" do
            lambda { executed_cmd.error! }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
          end
        end
      end

      it "includes output with exceptions from #error!" do
        cmd = Mixlib::ShellOut.new('ruby -e "exit 2"')
        cmd.run_command
        begin
          cmd.error!
        rescue Mixlib::ShellOut::ShellCommandFailed => e
          e.message.should match(Regexp.escape(cmd.format_for_exception))
        end
      end

      it "errors out when told the result is invalid" do
        cmd = Mixlib::ShellOut.new('ruby -e "exit 0"')
        cmd.run_command
        lambda { cmd.invalid!("I expected this to exit 42, not 0") }.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
      end
    end
  end

  describe "handling various subprocess behaviors" do
    it "collects all of STDOUT and STDERR" do
      twotime = %q{ruby -e 'STDERR.puts :hello; STDOUT.puts :world'}
      cmd = Mixlib::ShellOut.new(twotime)
      cmd.run_command
      cmd.stderr.should == "hello#{LINE_ENDING}"
      cmd.stdout.should == "world#{LINE_ENDING}"
    end

    it "collects the exit status of the command" do
      cmd = Mixlib::ShellOut.new('ruby -e "exit 0"')
      status = cmd.run_command.status
      status.exitstatus.should == 0
    end

    it "does not hang if a process forks but does not close stdout and stderr" do
      evil_forker="exit if fork; 10.times { sleep 1}"
      cmd = Mixlib::ShellOut.new("ruby -e '#{evil_forker}'")

      lambda {Timeout.timeout(2) do
        cmd.run_command
      end}.should_not raise_error
    end

    it "times out when a process takes longer than the specified timeout" do
      cmd = Mixlib::ShellOut.new("ruby -e \"sleep 2\"", :timeout => 0.1)
      lambda {cmd.run_command}.should raise_error(Mixlib::ShellOut::CommandTimeout)
    end

    it "reads all of the output when the subprocess produces more than $buffersize of output" do
      chatty = "ruby -e \"print('X' * 16 * 1024); print('.' * 1024)\""
      cmd = Mixlib::ShellOut.new(chatty)
      cmd.run_command
      cmd.stdout.should match(/X{16384}\.{1024}/)
    end

    it "returns empty strings from commands that have no output" do
      cmd = Mixlib::ShellOut.new(%q{ruby -e 'exit 0'})
      cmd.run_command
      cmd.stdout.should == ''
      cmd.stderr.should == ''
    end

    it "doesn't hang or lose output when a process closes one of stdout/stderr and continues writing to the other" do
      halfandhalf = %q{ruby -e 'STDOUT.close;sleep 0.5;STDERR.puts :win'}
      cmd = Mixlib::ShellOut.new(halfandhalf)
      cmd.run_command
      cmd.stderr.should == "win#{LINE_ENDING}"
    end

    it "does not deadlock when the subprocess writes lots of data to both stdout and stderr" do
      chatty = %q{ruby -e "puts 'f' * 20_000;STDERR.puts 'u' * 20_000; puts 'f' * 20_000;STDERR.puts 'u' * 20_000"}
      cmd = Mixlib::ShellOut.new(chatty)
      cmd.run_command
      cmd.stdout.should == ('f' * 20_000) + "#{LINE_ENDING}" + ('f' * 20_000) + "#{LINE_ENDING}"
      cmd.stderr.should == ('u' * 20_000) + "#{LINE_ENDING}" + ('u' * 20_000) + "#{LINE_ENDING}"
    end

    it "does not deadlock when the subprocess writes lots of data to both stdout and stderr (part2)" do
      chatty = %q{ruby -e "STDERR.puts 'u' * 20_000; puts 'f' * 20_000;STDERR.puts 'u' * 20_000; puts 'f' * 20_000"}
      cmd = Mixlib::ShellOut.new(chatty)
      cmd.run_command
      cmd.stdout.should == ('f' * 20_000) + "#{LINE_ENDING}" + ('f' * 20_000) + "#{LINE_ENDING}"
      cmd.stderr.should == ('u' * 20_000) + "#{LINE_ENDING}" + ('u' * 20_000) + "#{LINE_ENDING}"
    end

    it "doesn't hang or lose output when a process writes, pauses, then continues writing" do
      stop_and_go = %q{ruby -e 'puts "before";sleep 0.5;puts"after"'}
      cmd = Mixlib::ShellOut.new(stop_and_go)
      cmd.run_command
      cmd.stdout.should == "before#{LINE_ENDING}after#{LINE_ENDING}"
    end

    it "doesn't hang or lose output when a process pauses before writing" do
      late_arrival = %q{ruby -e 'sleep 0.5;puts "missed_the_bus"'}
      cmd = Mixlib::ShellOut.new(late_arrival)
      cmd.run_command
      cmd.stdout.should == "missed_the_bus#{LINE_ENDING}"
    end

    it "uses the C locale by default" do
      cmd = Mixlib::ShellOut.new(ECHO_LC_ALL)
      cmd.run_command
      cmd.stdout.strip.should == 'C'
    end

    it "does not set any locale when the user gives LC_ALL => nil" do
      # kinda janky
      cmd = Mixlib::ShellOut.new(ECHO_LC_ALL, :environment => {"LC_ALL" => nil})
      cmd.run_command
      if !ENV['LC_ALL'] && windows?
        expected = "%LC_ALL%"
      else
        expected = ENV['LC_ALL'].to_s.strip
      end
      cmd.stdout.strip.should == expected
    end

    it "uses the requested locale" do
      cmd = Mixlib::ShellOut.new(ECHO_LC_ALL, :environment => {"LC_ALL" => 'es'})
      cmd.run_command
      cmd.stdout.strip.should == 'es'
    end

    it "recovers the error message when exec fails" do
      cmd = Mixlib::ShellOut.new("fuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu")
      lambda {cmd.run_command}.should raise_error(Errno::ENOENT)
    end

    it "closes stdin on the child process so it knows not to wait for any input" do
      cmd = Mixlib::ShellOut.new(%q{ruby -e 'print STDIN.eof?.to_s'})
      cmd.run_command
      cmd.stdout.should == "true"
    end

    it "doesn't hang when STDOUT is closed before STDERR" do
      # Regression test:
      # We need to ensure that stderr is removed from the list of file
      # descriptors that we attempt to select() on in the case that:
      # a) STDOUT closes first
      # b) STDERR closes
      # c) The program does not exit for some time after (b) occurs.
      # Otherwise, we will attempt to read from the closed STDOUT pipe over and
      # over again and generate lots of garbage, which will not be collected
      # since we have to turn GC off to avoid segv.
      cmd = Mixlib::ShellOut.new(%q{ruby -e 'STDOUT.puts "F" * 4096; STDOUT.close; sleep 0.1; STDERR.puts "foo"; STDERR.close; sleep 0.1; exit'})
      cmd.run_command
      unclosed_pipes = cmd.send(:open_pipes)
      unclosed_pipes.should be_empty
    end
  end

  it "formats itself for exception messages" do
    cmd = Mixlib::ShellOut.new %q{ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"'}
    cmd.run_command
    cmd.format_for_exception.split("\n")[0].should == %q{---- Begin output of ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"' ----}
    cmd.format_for_exception.split("\n")[1].should == %q{STDOUT: msg_in_stdout}
    cmd.format_for_exception.split("\n")[2].should == %q{STDERR: msg_in_stderr}
    cmd.format_for_exception.split("\n")[3].should == %q{---- End output of ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"' ----}
  end


end
