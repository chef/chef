require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'tmpdir'
require 'tempfile'
require 'timeout'

describe Mixlib::ShellOut do
  before do
    @shell_cmd = Mixlib::ShellOut.new("apt-get install chef")
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
    unless windows?
      if username = Etc.getlogin
        expected_uid = Etc.getpwuid.uid
      else
        user_struct = Etc.getpwent
        username = user_struct.name
        expected_uid = user_struct.uid
      end

      @shell_cmd.user = Etc.getlogin
      @shell_cmd.uid.should == Etc.getpwuid.uid
    end
  end

  it "returns the user-supplied gid when present" do
    @shell_cmd.group = 0
    @shell_cmd.gid.should == 0
  end

  it "computes the gid of the user when a string/symbolic groupname is given" do
    unless windows?
      a_group = Etc.getgrent
      @shell_cmd.group = a_group.name
      @shell_cmd.gid.should == a_group.gid
    end
  end

  it "has a timeout defaulting to 600 seconds" do
    Mixlib::ShellOut.new('foo').timeout.should == 600
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
      @shell_cmd = Mixlib::ShellOut.new("brew install couchdb", @opts)
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
      @shell_cmd = Mixlib::ShellOut.new("brew install couchdb", :env => {'RUBY_OPTS'=>'-w'})
      @shell_cmd.environment.should == {'LC_ALL' => 'C', 'RUBY_OPTS' => '-w'}
    end

    it "does not set any environment settings when given :environment => nil" do
      @shell_cmd = Mixlib::ShellOut.new("brew install couchdb", :environment => nil)
      @shell_cmd.environment.should == {}
    end

    it "sets the list of acceptable return values" do
      @shell_cmd.valid_exit_codes.should == [0,1,42]
    end

    it "sets the live stream specified in the options" do
      @shell_cmd.live_stream.should == @opts[:live_stream]
    end

    it "raises an error when given an invalid option" do
      klass = Mixlib::ShellOut::InvalidCommandOption
      msg   = "option ':frab' is not a valid option for Mixlib::ShellOut"
      lambda { Mixlib::ShellOut.new("foo", :frab => :jab) }.should raise_error(klass, msg)
    end

    it "chdir to the cwd directory if given" do
      # /bin should exists on all systems, and is not the default cwd
      if windows?
        dir = Dir.tmpdir
        cmd = Mixlib::ShellOut.new('echo %cd%', :cwd => dir)
      else
        dir = "/bin"
        cmd = Mixlib::ShellOut.new('pwd', :cwd => dir)
      end
      cmd.run_command
      File.expand_path(cmd.stdout.chomp).should == File.expand_path(dir)
    end
  end

  context "when initialized with an array of command+args and an options hash" do
    before do
      @opts = {:cwd => '/tmp', :user => 'nobody'}
      @shell_cmd = Mixlib::ShellOut.new('ruby', '-e', %q{'puts "hello"'}, @opts)
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
      @shell_cmd = Mixlib::ShellOut.new('ruby', '-e', %q{'puts "hello"'})
    end

    it "sets the command to the array of command+args" do
      @shell_cmd.command.should == ['ruby', '-e', %q{'puts "hello"'}]
    end

  end

  context "when created with a live stream" do
    before do
      @stream = StringIO.new
      @shell_cmd = Mixlib::ShellOut.new(%q{ruby -e 'puts "hello"'}, :live_stream => @stream)
    end

    it "copies the subprocess' stdout to the live stream" do
      @shell_cmd.run_command
      @stream.string.should == "hello#{LINE_ENDING}"
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
  end

  it "formats itself for exception messages" do
    cmd = Mixlib::ShellOut.new %q{ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"'}
    cmd.run_command
    cmd.format_for_exception.split("\n")[0].should == %q{---- Begin output of ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"' ----}
    cmd.format_for_exception.split("\n")[1].should == %q{STDOUT: msg_in_stdout}
    cmd.format_for_exception.split("\n")[2].should == %q{STDERR: msg_in_stderr}
    cmd.format_for_exception.split("\n")[3].should == %q{---- End output of ruby -e 'STDERR.puts "msg_in_stderr"; puts "msg_in_stdout"' ----}
  end

  describe "running different types of command" do
    it "runs commands with spaces in the path" do
      Dir.mktmpdir do |dir|
        file = File.open("#{dir}/blah blah.cmd", "w")
        file.write(windows? ? "@echo blah" : "echo blah")
        file.close
        File.chmod(0755, file.path)

        cmd = Mixlib::ShellOut.new("\"#{file.path}\"")
        cmd.run_command
        cmd.stdout.chomp.should == "blah"
      end
    end

    it "runs commands with lots of long arguments" do
      # This number was chosen because it seems to be an actual maximum
      # in Windows--somewhere around 6-7K of command line
      echotext = 10000.upto(11340).map { |x| x.to_s }.join(' ')
      cmd = Mixlib::ShellOut.new("echo #{echotext}")
      cmd.run_command
      cmd.stdout.chomp.should == echotext
    end

    it "runs commands with quotes and special characters in quotes" do
      cmd = Mixlib::ShellOut.new(%q{ruby -e 'print "<>&|&&||;"'})
      cmd.run_command
      cmd.stdout.should == "<>&|&&||;"
    end

    it "runs commands with backslashes in them" do
      cmd = Mixlib::ShellOut.new(%q{ruby -e 'print "\\"\\\\"'})
      cmd.run_command
      cmd.stdout.should == "\"\\"
    end

    it "runs commands with stdout pipes" do
      Dir.mktmpdir do |dir|
        cmd = Mixlib::ShellOut.new("ruby -e 'STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false' | ruby -e 'print STDIN.read.length'")
        cmd.run_command
        cmd.stdout.should == "4"
        cmd.stderr.should == "false"
      end
    end

    it "runs commands with stdout file pipes" do
      Dir.mktmpdir do |dir|
        cmd = Mixlib::ShellOut.new("ruby -e 'STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false' > #{dir}/blah.txt")
        cmd.run_command
        cmd.stdout.should == ""
        cmd.stderr.should == "false"
        IO.read("#{dir}/blah.txt").should == "true"
      end
    end

    it "runs commands with stdout and stderr file pipes" do
      Dir.mktmpdir do |dir|
        cmd = Mixlib::ShellOut.new("ruby -e 'STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false' > #{dir}/blah.txt 2>&1")
        cmd.run_command
        cmd.stdout.should == ""
        IO.read("#{dir}/blah.txt").should == "truefalse"
      end
    end

    it "runs commands with &&" , :hi => true do
      cmd = Mixlib::ShellOut.new(%q{ruby -e 'print "foo"' && ruby -e 'print "bar"'})
      cmd.run_command
      cmd.stdout.should == "foobar"
    end

    it "runs commands with ||" do
      cmd = Mixlib::ShellOut.new(%q{ruby -e 'print "foo"; exit 1' || ruby -e 'print "bar"'})
      cmd.run_command
      cmd.status.exitstatus.should == 0
      cmd.stdout.should == "foobar"
    end
  end

  describe "handling process exit codes" do
    it "raises a InvalidCommandResult error if the exitstatus is nonzero" do
      cmd = Mixlib::ShellOut.new('ruby -e "exit 2"')
      cmd.run_command
      lambda {cmd.error!}.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
    end

    it "does not raise an error if the command returns a value in the list of valid_exit_codes" do
      cmd = Mixlib::ShellOut.new('ruby -e "exit 42"', :returns => 42)
      cmd.run_command
      lambda {cmd.error!}.should_not raise_error
    end

    it "raises an error if the command does not return a value in the list of valid_exit_codes" do
      cmd = Mixlib::ShellOut.new('ruby -e "exit 2"', :returns => [ 0, 1, 42 ])
      cmd.run_command
      lambda {cmd.error!}.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
    end

    it "raises an error if the command returns 0 and the list of valid_exit_codes does not contain 0" do
      cmd = Mixlib::ShellOut.new('ruby -e "exit 0"', :returns => 42)
      cmd.run_command
      lambda {cmd.error!}.should raise_error(Mixlib::ShellOut::ShellCommandFailed)
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
