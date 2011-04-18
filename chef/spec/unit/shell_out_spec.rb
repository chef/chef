require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Chef::ShellOut do
  before do
    @shell_cmd = Chef::ShellOut.new("apt-get install chef")
  end

  it "has a command" do
    @shell_cmd.command.should == "apt-get install chef"
  end

  it "defaults to not setting a working directory" do
    @shell_cmd.cwd.should == nil
  end

  it "has a user to run the command as" do
    @shell_cmd.user.should be_nil
  end

  it "sets the user to run the command as" do
    @shell_cmd.user = 'root'
    @shell_cmd.user.should == 'root'
  end

  it "has a group to run the command as" do
    @shell_cmd.group.should be_nil
  end

  it "sets the group to run the command as" do
    @shell_cmd.group = 'wheel'
    @shell_cmd.group.should == 'wheel'
  end

  it "has a set of environment variables to set before running the command" do
    @shell_cmd.environment.should == {"LC_ALL" => "C"}
  end

  it "has a umask" do
    @shell_cmd.umask.should be_nil
  end

  it "sets the umask using an octal integer" do
    @shell_cmd.umask = 007777
    @shell_cmd.umask.should == 007777
  end

  it "sets the umask using a decimal integer" do
    @shell_cmd.umask = 2925
    @shell_cmd.umask.should == 005555
  end

  it "sets the umask using a string representation of an integer" do
    @shell_cmd.umask = '7777'
    @shell_cmd.umask.should == 007777
  end

  it "returns the user-supplied uid when present" do
    @shell_cmd.user = 0
    @shell_cmd.uid.should == 0
  end

  it "computes the uid of the user when a string/symbolic username is given" do
    @shell_cmd.user = Etc.getlogin
    @shell_cmd.uid.should == Etc.getpwuid.uid
  end

  it "returns the user-supplied gid when present" do
    @shell_cmd.group = 0
    @shell_cmd.gid.should == 0
  end

  it "computes the gid of the user when a string/symbolic groupname is given" do
    a_group = Etc.getgrent
    @shell_cmd.group = a_group.name
    @shell_cmd.gid.should == a_group.gid
  end

  it "has a timeout defaulting to 60 seconds" do
    Chef::ShellOut.new('foo').timeout.should == 60
  end

  it "sets the read timeout" do
    @shell_cmd.timeout = 10
    @shell_cmd.timeout.should == 10
  end

  it "has a list of valid exit codes which is just 0 by default" do
    @shell_cmd.valid_exit_codes.should == [0]
  end

  it "sets the list of valid exit codes" do
    @shell_cmd.valid_exit_codes = [0,23,42]
    @shell_cmd.valid_exit_codes.should == [0,23,42]
  end

  it "defaults to not having a live stream" do
    @shell_cmd.live_stream.should be_nil
  end

  it "sets a live stream" do
    stream = StringIO.new
    @shell_cmd.live_stream = stream
    @shell_cmd.live_stream.should == stream
  end

  context "when initialized with a hash of options" do
    before do
      @opts = { :cwd => '/tmp', :user => 'toor', :group => 'wheel', :umask => '2222',
                :timeout => 5, :environment => {'RUBY_OPTS' => '-w'}, :returns => [0,1,42],
                :live_stream => StringIO.new}
      @shell_cmd = Chef::ShellOut.new("brew install couchdb", @opts)
    end

    it "sets the working dir as specified in the options" do
      @shell_cmd.cwd.should == '/tmp'
    end

    it "sets the user as specified in the options" do
      @shell_cmd.user.should == 'toor'
    end

    it "sets the group as specified in the options" do
      @shell_cmd.group.should == 'wheel'
    end

    it "sets the umask as specified in the options" do
      @shell_cmd.umask.should == 002222
    end

    it "sets the timout as specified in the options" do
      @shell_cmd.timeout.should == 5
    end

    it "merges the environment with the default environment settings" do
      @shell_cmd.environment.should == {'LC_ALL' => 'C', 'RUBY_OPTS' => '-w'}
    end

    it "also accepts :env to set the enviroment for brevity's sake" do
      @shell_cmd = Chef::ShellOut.new("brew install couchdb", :env => {'RUBY_OPTS'=>'-w'})
      @shell_cmd.environment.should == {'LC_ALL' => 'C', 'RUBY_OPTS' => '-w'}
    end

    it "does not set any environment settings when given :environment => nil" do
      @shell_cmd = Chef::ShellOut.new("brew install couchdb", :environment => nil)
      @shell_cmd.environment.should == {}
    end

    it "sets the list of acceptable return values" do
      @shell_cmd.valid_exit_codes.should == [0,1,42]
    end

    it "sets the live stream specified in the options" do
      @shell_cmd.live_stream.should == @opts[:live_stream]
    end

    it "raises an error when given an invalid option" do
      klass = Chef::Exceptions::InvalidCommandOption
      msg   = "option ':frab' is not a valid option for Chef::ShellOut"
      lambda { Chef::ShellOut.new("foo", :frab => :jab) }.should raise_error(klass, msg)
    end

    it "chdir to the cwd directory if given" do
      # /bin should exists on all systems, and is not the default cwd
      cmd = Chef::ShellOut.new('pwd', :cwd => '/bin')
      cmd.run_command
      cmd.stdout.should == "/bin\n"
    end
  end

  context "when initialized with an array of command+args and an options hash" do
    before do
      @opts = {:cwd => '/tmp', :user => 'nobody'}
      @shell_cmd = Chef::ShellOut.new('ruby', '-e', %q{'puts "hello"'}, @opts)
    end

    it "sets the command to the array of command and args" do
      @shell_cmd.command.should == ['ruby', '-e', %q{'puts "hello"'}]
    end

    it "evaluates the options" do
      @shell_cmd.cwd.should == '/tmp'
      @shell_cmd.user.should == 'nobody'
    end
  end

  context "when initialized with an array of command+args and no options" do
    before do
      @shell_cmd = Chef::ShellOut.new('ruby', '-e', %q{'puts "hello"'})
    end

    it "sets the command to the array of command+args" do
      @shell_cmd.command.should == ['ruby', '-e', %q{'puts "hello"'}]
    end

  end

  context "when created with a live stream" do
    before do
      @stream = StringIO.new
      @shell_cmd = Chef::ShellOut.new(%q{ruby -e 'puts "hello"'}, :live_stream => @stream)
    end

    it "copies the subprocess' stdout to the live stream" do
      @shell_cmd.run_command
      @stream.string.should == "hello\n"
    end
  end

  describe "handling various subprocess behaviors" do
    it "collects all of STDOUT and STDERR" do
      twotime = %q{ruby -e 'STDERR.puts :hello; STDOUT.puts :world'}
      cmd = Chef::ShellOut.new(twotime)
      cmd.run_command
      cmd.stderr.should == "hello\n"
      cmd.stdout.should == "world\n"
    end

    it "collects the exit status of the command" do
      cmd = Chef::ShellOut.new('ruby -e "exit 0"')
      status = cmd.run_command.status
      status.should be_a_kind_of(Process::Status)
      status.exitstatus.should == 0
    end

    it "does not hang if a process forks but does not close stdout and stderr" do
      evil_forker="exit if fork; 10.times { sleep 1}"
      cmd = Chef::ShellOut.new("ruby -e '#{evil_forker}'")

      lambda {Timeout.timeout(2) do
        cmd.run_command
      end}.should_not raise_error
    end

    it "times out when a process takes longer than the specified timeout" do
      cmd = Chef::ShellOut.new("sleep 2", :timeout => 0.1)
      lambda {cmd.run_command}.should raise_error(Chef::Exceptions::CommandTimeout)
    end

    it "reads all of the output when the subprocess produces more than $buffersize of output" do
      chatty = %q|ruby -e "print('X' * 16 * 1024); print( '.' * 1024)"|
      cmd = Chef::ShellOut.new(chatty)
      cmd.run_command
      cmd.stdout.should match(/X{16384}\.{1024}/)
    end

    it "returns empty strings from commands that have no output" do
      cmd = Chef::ShellOut.new(%q{ruby -e 'exit 0'})
      cmd.run_command
      cmd.stdout.should == ''
      cmd.stderr.should == ''
    end

    it "doesn't hang or lose output when a process closes one of stdout/stderr and continues writing to the other" do
      halfandhalf = %q{ruby -e 'STDOUT.close;sleep 0.5;STDERR.puts :win'}
      cmd = Chef::ShellOut.new(halfandhalf)
      cmd.run_command
      cmd.stderr.should == "win\n"
    end

    it "does not deadlock when the subprocess writes lots of data to both stdout and stderr" do
      chatty = %q{ruby -e "puts 'f' * 20_000;STDERR.puts 'u' * 20_000; puts 'f' * 20_000;STDERR.puts 'u' * 20_000"}
      cmd = Chef::ShellOut.new(chatty)
      cmd.run_command
      cmd.stdout.should == ('f' * 20_000) + "\n" + ('f' * 20_000) + "\n"
      cmd.stderr.should == ('u' * 20_000) + "\n" + ('u' * 20_000) + "\n"
    end

    it "does not deadlock when the subprocess writes lots of data to both stdout and stderr (part2)" do
      chatty = %q{ruby -e "STDERR.puts 'u' * 20_000; puts 'f' * 20_000;STDERR.puts 'u' * 20_000; puts 'f' * 20_000"}
      cmd = Chef::ShellOut.new(chatty)
      cmd.run_command
      cmd.stdout.should == ('f' * 20_000) + "\n" + ('f' * 20_000) + "\n"
      cmd.stderr.should == ('u' * 20_000) + "\n" + ('u' * 20_000) + "\n"
    end

    it "doesn't hang or lose output when a process writes, pauses, then continues writing" do
      stop_and_go = %q{ruby -e 'puts "before";sleep 0.5;puts"after"'}
      cmd = Chef::ShellOut.new(stop_and_go)
      cmd.run_command
      cmd.stdout.should == "before\nafter\n"
    end

    it "doesn't hang or lose output when a process pauses before writing" do
      late_arrival = %q{ruby -e 'sleep 0.5;puts "missed_the_bus"'}
      cmd = Chef::ShellOut.new(late_arrival)
      cmd.run_command
      cmd.stdout.should == "missed_the_bus\n"
    end

    it "uses the C locale by default" do
      cmd = Chef::ShellOut.new('echo $LC_ALL')
      cmd.run_command
      cmd.stdout.strip.should == 'C'
    end

    it "does not set any locale when the user gives LC_ALL => nil" do
      # kinda janky
      cmd = Chef::ShellOut.new('echo $LC_ALL', :environment => {"LC_ALL" => nil})
      cmd.run_command
      cmd.stdout.strip.should == ENV['LC_ALL'].to_s.strip
    end

    it "uses the requested locale" do
      cmd = Chef::ShellOut.new('echo $LC_ALL', :environment => {"LC_ALL" => 'es'})
      cmd.run_command
      cmd.stdout.strip.should == 'es'
    end

    it "recovers the error message when exec fails" do
      cmd = Chef::ShellOut.new("fuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu")
      lambda {cmd.run_command}.should raise_error(Errno::ENOENT)
    end

    it "closes stdin on the child process so it knows not to wait for any input" do
      cmd = Chef::ShellOut.new(%q{ruby -e 'print STDIN.eof?.to_s'})
      cmd.run_command
      cmd.stdout.should == "true"
    end
  end

  it "formats itself for exception messages" do
    cmd = Chef::ShellOut.new %q{ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"'}
    cmd.run_command
    cmd.format_for_exception.split("\n")[0].should == %q{---- Begin output of ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"' ----}
    cmd.format_for_exception.split("\n")[1].should == %q{STDOUT: msg_in_stdout}
    cmd.format_for_exception.split("\n")[2].should == %q{STDERR: msg_in_stderr}
    cmd.format_for_exception.split("\n")[3].should == %q{---- End output of ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"' ----}
  end

  it "raises a InvalidCommandResult error if the exitstatus is an unexpected value" do
    cmd = Chef::ShellOut.new('ruby -e "exit 2"')
    cmd.run_command
    lambda {cmd.error!}.should raise_error(Chef::Exceptions::ShellCommandFailed)
  end

  it "does not raise an error if the command returns a value in the list of valid_exit_codes" do
    cmd = Chef::ShellOut.new('ruby -e "exit 42"', :returns => 42)
    cmd.run_command
    lambda {cmd.error!}.should_not raise_error
  end

  it "includes output with exceptions from #error!" do
    cmd = Chef::ShellOut.new('ruby -e "exit 2"')
    cmd.run_command
    begin
      cmd.error!
    rescue Chef::Exceptions::ShellCommandFailed => e
      e.message.should match(Regexp.escape(cmd.format_for_exception))
    end
  end

  it "errors out when told the result is invalid" do
    cmd = Chef::ShellOut.new('ruby -e "exit 0"')
    cmd.run_command
    lambda { cmd.invalid!("I expected this to exit 42, not 0") }.should raise_error(Chef::Exceptions::ShellCommandFailed)
  end

end
