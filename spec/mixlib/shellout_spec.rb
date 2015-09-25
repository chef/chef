require 'spec_helper'
require 'logger'
require 'timeout'

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
      expect(subject.command).to eql(cmd)
    end

    context 'with default settings' do
      describe '#cwd' do
        subject { super().cwd }
        it { is_expected.to be_nil }
      end

      describe '#user' do
        subject { super().user }
        it { is_expected.to be_nil }
      end

      describe '#with_logon' do
        subject { super().with_logon }
        it { is_expected.to be_nil }
      end

      describe '#login' do
        subject { super().login }
        it { is_expected.to be_nil }
      end

      describe '#domain' do
        subject { super().domain }
        it { is_expected.to be_nil }
      end

      describe '#password' do
        subject { super().password }
        it { is_expected.to be_nil }
      end

      describe '#group' do
        subject { super().group }
        it { is_expected.to be_nil }
      end

      describe '#umask' do
        subject { super().umask }
        it { is_expected.to be_nil }
      end

      describe '#timeout' do
        subject { super().timeout }
        it { is_expected.to eql(600) }
      end

      describe '#valid_exit_codes' do
        subject { super().valid_exit_codes }
        it { is_expected.to eql([0]) }
      end

      describe '#live_stream' do
        subject { super().live_stream }
        it { is_expected.to be_nil }
      end

      describe '#input' do
        subject { super().input }
        it { is_expected.to be_nil }
      end

      it "should not set any default environmental variables" do
        expect(shell_cmd.environment).to eq({})
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
          is_expected.to eql(value)
        end

        # TODO add :unix_only
        context 'with an integer value for user' do
          let(:value) { 0 }
          it "should use the user-supplied uid" do
            expect(shell_cmd.uid).to eql(value)
          end
        end

        # TODO add :unix_only
        context 'with string value for user' do
          let(:value) { username }

          let(:username) { user_info.name }
          let(:expected_uid) { user_info.uid }
          let(:user_info) { Etc.getpwent }

          it "should compute the uid of the user", :unix_only do
            expect(shell_cmd.uid).to eql(expected_uid)
          end
        end
      end

      context 'when setting with_logon' do
        let(:accessor) { :with_logon }
        let(:value) { 'root' }

        it "should set the with_logon" do
          is_expected.to eql(value)
        end
      end

      context 'when setting login' do
        let(:accessor) { :login }
        let(:value) { true }

        it "should set the login" do
          is_expected.to eql(value)
        end
      end

      context 'when setting domain' do
        let(:accessor) { :domain }
        let(:value) { 'localhost' }

        it "should set the domain" do
          is_expected.to eql(value)
        end
      end

      context 'when setting password' do
        let(:accessor) { :password }
        let(:value) { 'vagrant' }

        it "should set the password" do
          is_expected.to eql(value)
        end
      end

      context 'when setting group' do
        let(:accessor) { :group }
        let(:value) { 'wheel' }

        it "should set the group" do
          is_expected.to eql(value)
        end

        # TODO add :unix_only
        context 'with integer value for group' do
          let(:value) { 0 }
          it "should use the user-supplied gid" do
            expect(shell_cmd.gid).to eql(value)
          end
        end

        context 'with string value for group' do
          let(:value) { groupname }
          let(:groupname) { group_info.name }
          let(:expected_gid) { group_info.gid }
          let(:group_info) { Etc.getgrent }

          it "should compute the gid of the user", :unix_only do
            expect(shell_cmd.gid).to eql(expected_gid)
          end
        end
      end

      context 'when setting the umask' do
        let(:accessor) { :umask }

        context 'with octal integer' do
          let(:value) { 007555}

          it 'should set the umask' do
            is_expected.to eql(value)
          end
        end

        context 'with decimal integer' do
          let(:value) { 2925 }

          it 'should sets the umask' do
            is_expected.to eql(005555)
          end
        end

        context 'with string' do
          let(:value) { '7777' }

          it 'should sets the umask' do
            is_expected.to eql(007777)
          end
        end
      end

      context 'when setting read timeout' do
        let(:accessor) { :timeout }
        let(:value) { 10 }

        it 'should set the read timeout' do
          is_expected.to eql(value)
        end
      end

      context 'when setting valid exit codes' do
        let(:accessor) { :valid_exit_codes }
        let(:value) { [0, 23, 42] }

        it "should set the valid exit codes" do
          is_expected.to eql(value)
        end
      end

      context 'when setting a live stream' do
        let(:accessor) { :live_stream }
        let(:value) { stream }
        let(:stream) { StringIO.new }

        before(:each) do
          shell_cmd.live_stream = stream
        end

        it "live stream should return the stream used for live stdout and live stderr" do
          expect(shell_cmd.live_stream).to eql(stream)
        end

        it "should set the live stdout stream" do
          expect(shell_cmd.live_stderr).to eql(stream)
        end

        it "should set the live stderr stream" do
          expect(shell_cmd.live_stderr).to eql(stream)
        end
      end

      context 'when setting the live stdout and live stderr streams separately' do
        let(:accessor) { :live_stream }
        let(:stream) { StringIO.new }
        let(:value) { stream }
        let(:stdout_stream) { StringIO.new }
        let(:stderr_stream) { StringIO.new }

        before(:each) do
          shell_cmd.live_stdout = stdout_stream
          shell_cmd.live_stderr = stderr_stream
        end

        it "live_stream should return nil" do
          expect(shell_cmd.live_stream).to be_nil
        end

        it "should set the live stdout" do
          expect(shell_cmd.live_stdout).to eql(stdout_stream)
        end

        it "should set the live stderr" do
          expect(shell_cmd.live_stderr).to eql(stderr_stream)
        end
      end

      context 'when setting a live stream and then overriding the live stderr' do
        let(:accessor) { :live_stream }
        let(:value) { stream }
        let(:stream) { StringIO.new }

        before(:each) do
          shell_cmd.live_stdout = stream
          shell_cmd.live_stderr = nil
        end

        it "should return nil" do
          is_expected.to be_nil
        end

        it "should set the live stdout" do
          expect(shell_cmd.live_stdout).to eql(stream)
        end

        it "should set the live stderr" do
          expect(shell_cmd.live_stderr).to eql(nil)
        end
      end

      context 'when setting an input' do
        let(:accessor) { :input }
        let(:value) { "Random content #{rand(1000000)}" }

        it "should set the input" do
          is_expected.to eql(value)
        end
      end
    end

    context 'testing login', :unix_only do
      subject {shell_cmd}
      let (:uid) {1005}
      let (:gid) {1002}
      let (:shell) {'/bin/money'}
      let (:dir) {'/home/castle'}
      let (:path) {'/sbin:/bin:/usr/sbin:/usr/bin'}
      before :each do
        shell_cmd.login=true
        catbert_user=double("Etc::Passwd", :name=>'catbert', :passwd=>'x', :uid=>1005, :gid=>1002, :gecos=>"Catbert,,,", :dir=>'/home/castle', :shell=>'/bin/money')
        group_double=[
          double("Etc::Group", :name=>'catbert', :passwd=>'x', :gid=>1002, :mem=>[]),
          double("Etc::Group", :name=>'sudo', :passwd=>'x', :gid=>52, :mem=>['catbert']),
          double("Etc::Group", :name=>'rats', :passwd=>'x', :gid=>43, :mem=>['ratbert']),
          double("Etc::Group", :name=>'dilbertpets', :passwd=>'x', :gid=>700, :mem=>['catbert', 'ratbert']),
        ]
        allow(Etc).to receive(:getpwuid).with(1005) {catbert_user}
        allow(Etc).to receive(:getpwnam).with('catbert') {catbert_user}
        allow(shell_cmd).to receive(:all_seconderies) {group_double}
      end

      # Setting the user by name should change the uid
      context 'when setting user by name' do
        before(:each){ shell_cmd.user='catbert' }
          describe '#uid' do
            subject { super().uid }
            it { is_expected.to eq(uid) }
          end
      end

      context 'when setting user by id' do
        before(:each){shell_cmd.user=uid}
        # Setting the user by uid should change the uid
        #it 'should set the uid' do

        describe '#uid' do
          subject { super().uid }
          it { is_expected.to eq(uid) }
        end
        #end
        # Setting the user without a different gid should change the gid to 1002

        describe '#gid' do
          subject { super().gid }
          it { is_expected.to eq(gid) }
        end
        # Setting the user and the group (to 43) should change the gid to 43
        context 'when setting the group manually' do
          before(:each){shell_cmd.group=43}

          describe '#gid' do
            subject { super().gid }
            it {is_expected.to eq(43)}
          end
        end
        # Setting the user should set the env variables
	describe '#process_environment' do
	  subject { super().process_environment }
	  it { is_expected.to eq ({'HOME'=>dir, 'SHELL'=>shell, 'USER'=>'catbert', 'LOGNAME'=>'catbert', 'PATH'=>path, 'IFS'=>"\t\n"}) }
	end
        # Setting the user with overriding env variables should override
	context 'when adding environment variables' do
	  before(:each){shell_cmd.environment={'PATH'=>'/lord:/of/the/dance', 'CUSTOM'=>'costume'}}
	  it 'should preserve custom variables' do
	    expect(shell_cmd.process_environment['PATH']).to eq('/lord:/of/the/dance')
	  end
          # Setting the user with additional env variables should have both
	  it 'should allow new variables' do
	    expect(shell_cmd.process_environment['CUSTOM']).to eq('costume')
	  end
	end
        # Setting the user should set secondary groups
	describe '#sgids' do
	  subject { super().sgids }
	  it { is_expected.to match_array([52,700]) }
	end
      end
      # Setting login with user should throw errors
      context 'when not setting a user id' do
        it 'should fail showing an error' do
          expect { Mixlib::ShellOut.new('hostname', {login:true}) }.to raise_error(Mixlib::ShellOut::InvalidCommandOption)
        end
      end
    end

    context "with options hash" do
      let(:cmd) { 'brew install couchdb' }
      let(:options) { { :cwd => cwd, :user => user, :login => true, :domain => domain, :password => password, :group => group,
        :umask => umask, :timeout => timeout, :environment => environment, :returns => valid_exit_codes,
        :live_stream => stream, :input => input } }

      let(:cwd) { '/tmp' }
      let(:user) { 'toor' }
      let(:with_logon) { user }
      let(:login) { true }
      let(:domain) { 'localhost' }
      let(:password) { 'vagrant' }
      let(:group) { 'wheel' }
      let(:umask) { '2222' }
      let(:timeout) { 5 }
      let(:environment) { { 'RUBY_OPTS' => '-w' } }
      let(:valid_exit_codes) { [ 0, 1, 42 ] }
      let(:stream) { StringIO.new }
      let(:input) { 1.upto(10).map { "Data #{rand(100000)}" }.join("\n") }

      it "should set the working directory" do
        expect(shell_cmd.cwd).to eql(cwd)
      end

      it "should set the user" do
        expect(shell_cmd.user).to eql(user)
      end

      it "should set the with_logon" do
        expect(shell_cmd.with_logon).to eql(with_logon)
      end

      it "should set the login" do
        expect(shell_cmd.login).to eql(login)
      end

      it "should set the domain" do
        expect(shell_cmd.domain).to eql(domain)
      end

      it "should set the password" do
        expect(shell_cmd.password).to eql(password)
      end

      it "should set the group" do
        expect(shell_cmd.group).to eql(group)
      end

      it "should set the umask" do
        expect(shell_cmd.umask).to eql(002222)
      end

      it "should set the timout" do
        expect(shell_cmd.timeout).to eql(timeout)
      end

      it "should add environment settings to the default" do
        expect(shell_cmd.environment).to eql({'RUBY_OPTS' => '-w'})
      end

      context 'when setting custom environments' do
        context 'when setting the :env option' do
          let(:options) { { :env => environment } }

          it "should also set the enviroment" do
            expect(shell_cmd.environment).to eql({'RUBY_OPTS' => '-w'})
          end
        end

        context 'when :environment is set to nil' do
          let(:options) { { :environment => nil } }

          it "should not set any environment" do
            expect(shell_cmd.environment).to eq({})
          end
        end

        context 'when :env is set to nil' do
          let(:options) { { :env => nil } }

          it "should not set any environment" do
            expect(shell_cmd.environment).to eql({})
          end
        end
      end

      it "should set valid exit codes" do
        expect(shell_cmd.valid_exit_codes).to eql(valid_exit_codes)
      end

      it "should set the live stream" do
        expect(shell_cmd.live_stream).to eql(stream)
      end

      it "should set the input" do
        expect(shell_cmd.input).to eql(input)
      end

      context 'with an invalid option' do
        let(:options) { { :frab => :job } }
        let(:invalid_option_exception) { Mixlib::ShellOut::InvalidCommandOption }
        let(:exception_message) { "option ':frab' is not a valid option for Mixlib::ShellOut" }

        it "should raise InvalidCommandOPtion" do
          expect { shell_cmd }.to raise_error(invalid_option_exception, exception_message)
        end
      end
    end

    context "with array of command and args" do
      let(:cmd) { [ 'ruby', '-e', %q{'puts "hello"'} ] }

      context 'without options' do
        let(:options) { nil }

        it "should set the command to the array of command and args" do
          expect(shell_cmd.command).to eql(cmd)
        end
      end

      context 'with options' do
        let(:options) { {:cwd => '/tmp', :user => 'nobody', :password => "something"} }

        it "should set the command to the array of command and args" do
          expect(shell_cmd.command).to eql(cmd)
        end

        it "should evaluate the options" do
          expect(shell_cmd.cwd).to eql('/tmp')
          expect(shell_cmd.user).to eql('nobody')
          expect(shell_cmd.password).to eql('something')
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

      context 'when running under Unix', :unix_only do
        # Use /bin for tests only if it is not a symlink. Some
        # distributions (e.g. Fedora) symlink it to /usr/bin
        let(:cwd) { File.symlink?('/bin') ? '/tmp' : '/bin' }
        let(:cmd) { 'pwd' }

        it "should chdir to the working directory" do
          is_expected.to eql(fully_qualified_cwd)
        end
      end

      context 'when running under Windows', :windows_only do
        let(:cwd) { Dir.tmpdir }
        let(:cmd) { 'echo %cd%' }

        it "should chdir to the working directory" do
          is_expected.to eql(fully_qualified_cwd)
        end
      end
    end

    context 'when handling locale' do
      before do
        @original_lc_all = ENV['LC_ALL']
        ENV['LC_ALL'] = "en_US.UTF-8"
      end
      after do
        ENV['LC_ALL'] = @original_lc_all
      end

      subject { stripped_stdout }
      let(:cmd) { ECHO_LC_ALL }
      let(:options) { { :environment => { 'LC_ALL' => locale } } }

      context 'without specifying environment' do
        let(:options) { nil }
        it "should no longer use the C locale by default" do
          is_expected.to eql("en_US.UTF-8")
        end
      end

      context 'with locale' do
        let(:locale) { 'es' }

        it "should use the requested locale" do
          is_expected.to eql(locale)
        end
      end

      context 'with LC_ALL set to nil' do
        let(:locale) { nil }

        context 'when running under Unix', :unix_only do
          it "should unset the process's locale" do
            is_expected.to eql("")
          end
        end

        context 'when running under Windows', :windows_only do
          it "should unset process's locale" do
            is_expected.to eql('%LC_ALL%')
          end
        end
      end
    end

    context "when running under Windows", :windows_only do
      let(:cmd) { '%windir%/system32/whoami.exe' }
      let(:running_user) { shell_cmd.run_command.stdout.strip.downcase }

      context "when no user is set" do
        # Need to adjust the username and domain if running as local system
        # to match how whoami returns the information

        it "should run as current user" do
          expect(running_user).to eql("#{ENV['USERDOMAIN'].downcase}\\#{ENV['USERNAME'].downcase}")
        end
      end

      context "when user is specified" do
        before do
          expect(system("net user #{user} #{password} /add")).to eq(true)
        end

        after do
          expect(system("net user #{user} /delete")).to eq(true)
        end

        let(:user) { 'testuser' }
        let(:password) { 'testpass1!' }
        let(:options) { { :user => user, :password => password } }

        it "should run as specified user" do
          expect(running_user).to eql("#{ENV['COMPUTERNAME'].downcase}\\#{user}")
        end
      end
    end

    context "with a live stream" do
      let(:stream) { StringIO.new }
      let(:ruby_code) { '$stdout.puts "hello"; $stderr.puts "world"' }
      let(:options) { { :live_stream => stream } }

      it "should copy the child's stdout to the live stream" do
        shell_cmd.run_command
        expect(stream.string).to include("hello#{LINE_ENDING}")
      end

      context "with default live stderr" do
        it "should copy the child's stderr to the live stream" do
          shell_cmd.run_command
          expect(stream.string).to include("world#{LINE_ENDING}")
        end
      end

      context "without live stderr" do
        it "should not copy the child's stderr to the live stream" do
          shell_cmd.live_stderr = nil
          shell_cmd.run_command
          expect(stream.string).not_to include("world#{LINE_ENDING}")
        end
      end

      context "with a separate live stderr" do
        let(:stderr_stream) { StringIO.new }

        it "should not copy the child's stderr to the live stream" do
          shell_cmd.live_stderr = stderr_stream
          shell_cmd.run_command
          expect(stream.string).not_to include("world#{LINE_ENDING}")
        end

        it "should copy the child's stderr to the live stderr stream" do
          shell_cmd.live_stderr = stderr_stream
          shell_cmd.run_command
          expect(stderr_stream.string).to include("world#{LINE_ENDING}")
        end
      end
    end

    context "with an input" do
      subject { stdout }

      let(:input) { 'hello' }
      let(:ruby_code) { 'STDIN.sync = true; STDOUT.sync = true; puts gets' }
      let(:options) { { :input => input } }

      it "should copy the input to the child's stdin" do
        is_expected.to eql("hello#{LINE_ENDING}")
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

        context 'when running under Unix', :unix_only do
          let(:script_content) { 'echo blah' }

          it 'should execute' do
            is_expected.to eql('blah')
          end
        end

        context 'when running under Windows', :windows_only do
          let(:cmd) { "#{script_name} #{argument}" }
          let(:script_content) { '@echo %1' }
          let(:argument) { rand(10000).to_s }

          it 'should execute' do
            is_expected.to eql(argument)
          end

          context 'with multiple quotes in the command and args' do
            context 'when using a batch file' do
              let(:argument) { "\"Random #{rand(10000)}\"" }

              it 'should execute' do
                is_expected.to eql(argument)
              end
            end

            context 'when not using a batch file' do
              let(:cmd) { "#{executable_file_name} #{script_name}" }

              let(:executable_file_name) { "\"#{dir}/Ruby Parser.exe\"".tap(&make_executable!) }
              let(:make_executable!) { lambda { |filename| Mixlib::ShellOut.new("copy \"#{full_path_to_ruby}\" #{filename}").run_command } }
              let(:script_content) { "print \"#{expected_output}\"" }
              let(:expected_output) { "Random #{rand(10000)}" }

              let(:full_path_to_ruby) { ENV['PATH'].split(';').map(&try_ruby).reject(&:nil?).first }
              let(:try_ruby) { lambda { |path| "#{path}\\ruby.exe" if File.executable? "#{path}\\ruby.exe" } }

              it 'should execute' do
                is_expected.to eql(expected_output)
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
          is_expected.to eql(echotext)
        end
      end

      context 'with special characters' do
        subject { stdout }

        let(:special_characters) { '<>&|&&||;' }
        let(:ruby_code) { "print \"#{special_characters}\"" }

        it 'should execute' do
          is_expected.to eql(special_characters)
        end
      end

      context 'with backslashes' do
        subject { stdout }
        let(:backslashes) { %q{\\"\\\\} }
        let(:cmd) { ruby_eval.call("print \"#{backslashes}\"") }

        it 'should execute' do
          is_expected.to eql("\"\\")
        end
      end

      context 'with pipes' do
        let(:input_script) { "STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false" }
        let(:output_script) { "print STDIN.read.length" }
        let(:cmd) { ruby_eval.call(input_script) + " | " + ruby_eval.call(output_script) }

        it 'should execute' do
          expect(stdout).to eql('4')
        end

        it 'should handle stderr' do
          expect(stderr).to eql('false')
        end
      end

      context 'with stdout and stderr file pipes' do
        let(:code) { "STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false" }
        let(:cmd) { ruby_eval.call(code) + " > #{dump_file}" }

        it 'should execute' do
          expect(stdout).to eql('')
        end

        it 'should handle stderr' do
          expect(stderr).to eql('false')
        end

        it 'should write to file pipe' do
          expect(dump_file_content).to eql('true')
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
          expect(stdout).to eql(file_content)
        end

        it 'should handle stderr' do
          expect(stderr).to eql('false')
        end
      end

      context 'with stdout and stderr file pipes' do
        let(:code) { "STDOUT.sync = true; STDERR.sync = true; print true; STDERR.print false" }
        let(:cmd) { ruby_eval.call(code) + " > #{dump_file} 2>&1" }

        it 'should execute' do
          expect(stdout).to eql('')
        end

        it 'should write to file pipe' do
          expect(dump_file_content).to eql('truefalse')
        end
      end

      context 'with &&' do
        subject { stdout }
        let(:cmd) { ruby_eval.call('print "foo"') + ' && ' + ruby_eval.call('print "bar"') }

        it 'should execute' do
          is_expected.to eql('foobar')
        end
      end

      context 'with ||' do
        let(:cmd) { ruby_eval.call('print "foo"; exit 1') + ' || ' + ruby_eval.call('print "bar"') }

        it 'should execute' do
          expect(stdout).to eql('foobar')
        end

        it 'should exit with code 0' do
          expect(exit_status).to eql(0)
        end
      end
    end

    context "when handling process exit codes" do
      let(:cmd) { ruby_eval.call("exit #{exit_code}") }

      context 'with normal exit status' do
        let(:exit_code) { 0 }

        it "should not raise error" do
          expect { executed_cmd.error! }.not_to raise_error
        end

        it "should set the exit status of the command" do
          expect(exit_status).to eql(exit_code)
        end
      end

      context 'with nonzero exit status' do
        let(:exit_code) { 2 }
        let(:exception_message_format) { Regexp.escape(executed_cmd.format_for_exception) }

        it "should raise ShellCommandFailed" do
          expect { executed_cmd.error! }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
        end

        it "includes output with exceptions from #error!" do
          begin
            executed_cmd.error!
          rescue Mixlib::ShellOut::ShellCommandFailed => e
            expect(e.message).to match(exception_message_format)
          end
        end

        it "should set the exit status of the command" do
          expect(exit_status).to eql(exit_code)
        end
      end

      context 'with valid exit codes' do
        let(:cmd) { ruby_eval.call("exit #{exit_code}" ) }
        let(:options) { { :returns => valid_exit_codes } }

        context 'when exiting with valid code' do
          let(:valid_exit_codes) { 42 }
          let(:exit_code) { 42 }

          it "should not raise error" do
            expect { executed_cmd.error! }.not_to raise_error
          end

          it "should set the exit status of the command" do
            expect(exit_status).to eql(exit_code)
          end
        end

        context 'when exiting with invalid code' do
          let(:valid_exit_codes) { [ 0, 1, 42 ] }
          let(:exit_code) { 2 }

          it "should raise ShellCommandFailed" do
            expect { executed_cmd.error! }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
          end

          it "should set the exit status of the command" do
            expect(exit_status).to eql(exit_code)
          end

          context 'with input data' do
            let(:options) { { :returns => valid_exit_codes, :input => input } }
            let(:input) { "Random data #{rand(1000000)}" }

            it "should raise ShellCommandFailed" do
              expect { executed_cmd.error! }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
            end

            it "should set the exit status of the command" do
              expect(exit_status).to eql(exit_code)
            end
          end
        end

        context 'when exiting with invalid code 0' do
          let(:valid_exit_codes) { 42 }
          let(:exit_code) { 0 }

          it "should raise ShellCommandFailed" do
            expect { executed_cmd.error! }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
          end

          it "should set the exit status of the command" do
            expect(exit_status).to eql(exit_code)
          end
        end
      end

      describe "#invalid!" do
        let(:exit_code) { 0 }

        it "should raise ShellCommandFailed" do
          expect { executed_cmd.invalid!("I expected this to exit 42, not 0") }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
        end
      end

      describe "#error?" do
        context 'when exiting with invalid code' do
          let(:exit_code) { 2 }

          it "should return true" do
            expect(executed_cmd.error?).to be_truthy
          end
        end

        context 'when exiting with valid code' do
          let(:exit_code) { 0 }

          it "should return false" do
            expect(executed_cmd.error?).to be_falsey
          end
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
          expect(stderr).to eql("hello#{LINE_ENDING}")
          expect(stdout).to eql("world#{LINE_ENDING}")
        end
      end

      context 'with forking subprocess that does not close stdout and stderr' do
        let(:ruby_code) { "exit if fork; 10.times { sleep 1 }" }

        it "should not hang" do
          expect do
            Timeout.timeout(2) do
              executed_cmd
            end
          end.not_to raise_error
        end
      end

      context "when running a command that doesn't exist", :unix_only do

        let(:cmd) { "/bin/this-is-not-a-real-command" }

        def shell_out_cmd
          Mixlib::ShellOut.new(cmd)
        end

        it "reaps zombie processes after exec fails [OHAI-455]" do
          # NOTE: depending on ulimit settings, GC, etc., before the OHAI-455 patch,
          # ohai could also exhaust the available file descriptors when creating this
          # many zombie processes. A regression _could_ cause Errno::EMFILE but this
          # probably won't be consistent on different environments.
          created_procs = 0
          100.times do
            begin
              shell_out_cmd.run_command
            rescue Errno::ENOENT
              created_procs += 1
            end
          end
          expect(created_procs).to eq(100)
          reaped_procs = 0
          begin
            loop { Process.wait(-1); reaped_procs += 1 }
          rescue Errno::ECHILD
          end
          expect(reaped_procs).to eq(0)
        end
      end

      context 'with open files for parent process' do
        before do
          @test_file = Tempfile.new('fd_test')
          @test_file.write("hello")
          @test_file.flush
        end

        after do
          @test_file.close if @test_file
        end

        let(:ruby_code) { "fd = File.for_fd(#{@test_file.to_i}) rescue nil; if fd; fd.seek(0); puts fd.read(5); end" }

        it "should not see file descriptors of the parent" do
          # The reason this test goes through the effor of writing out
          # a file and checking the contents along side the presence of
          # a file descriptor is because on Windows, we're seeing that
          # a there is a file descriptor present, but it's not the same
          # file. That means that if we just check for the presence of
          # a file descriptor, the test would fail as that slot would
          # have something.
          #
          # See https://github.com/chef/mixlib-shellout/pull/103
          #
          expect(stdout.chomp).not_to eql("hello")
        end
      end

      context "when the child process dies immediately" do
        let(:cmd) { [ 'exit' ] }

        it "handles ESRCH from getpgid of a zombie", :unix_only do
          allow(Process).to receive(:setsid) { exit!(4) }

          # we used to have race conditions if the child exited and zombied
          # quickly which would cause an exception.  we no longer call getpgrp()
          # after setsid()/setpgrp() though so this race condition should no
          # longer exist.  still test 5 times for it though.
          5.times do
            s = Mixlib::ShellOut.new(cmd)
            s.run_command # should not raise Errno::ESRCH (or anything else)
          end

        end

      end

      context 'with subprocess that takes longer than timeout' do
        let(:options) { { :timeout => 1 } }

        context 'on windows', :windows_only do
          let(:cmd) do
            'powershell -c "sleep 10"'
          end

          before do
            require "wmi-lite/wmi"
            allow(WmiLite::Wmi).to receive(:new)
            allow(Mixlib::ShellOut::Windows::Utils).to receive(:kill_process_tree)
          end

          it "should raise CommandTimeout" do
            Timeout::timeout(5) do
              expect { executed_cmd }.to raise_error(Mixlib::ShellOut::CommandTimeout)
            end
          end

          context 'and child processes should be killed' do
            it 'kills the child processes' do
              expect(Mixlib::ShellOut::Windows::Utils).to receive(:kill_process_tree)
              expect { executed_cmd }.to raise_error(Mixlib::ShellOut::CommandTimeout)
            end
          end
        end

        context 'on unix', :unix_only do
          def ruby_wo_shell(code)
            parts = %w[ruby]
            parts << "--disable-gems" if ruby_19?
            parts << "-e"
            parts << code
          end

          let(:cmd) do
            ruby_wo_shell(<<-CODE)
              STDOUT.sync = true
              trap(:TERM) { puts "got term"; exit!(123) }
              sleep 10
            CODE
          end

          it "should raise CommandTimeout" do
            expect { executed_cmd }.to raise_error(Mixlib::ShellOut::CommandTimeout)
          end

          it "should ask the process nicely to exit" do
            # note: let blocks don't correctly memoize if an exception is raised,
            # so can't use executed_cmd
            expect { shell_cmd.run_command }.to raise_error(Mixlib::ShellOut::CommandTimeout)
            expect(shell_cmd.stdout).to include("got term")
            expect(shell_cmd.exitstatus).to eq(123)
          end

          context "and the child is unresponsive" do
            let(:cmd) do
              ruby_wo_shell(<<-CODE)
                STDOUT.sync = true
                trap(:TERM) { puts "nanana cant hear you" }
                sleep 10
              CODE
            end

            it "should KILL the wayward child" do
              # note: let blocks don't correctly memoize if an exception is raised,
              # so can't use executed_cmd
              expect { shell_cmd.run_command}.to raise_error(Mixlib::ShellOut::CommandTimeout)
              expect(shell_cmd.stdout).to include("nanana cant hear you")
              expect(shell_cmd.status.termsig).to eq(9)
            end

            context "and a logger is configured" do
              let(:log_output) { StringIO.new }
              let(:logger) { Logger.new(log_output) }
              let(:options) { {:timeout => 1, :logger => logger} }

              it "should log messages about killing the child process" do
                # note: let blocks don't correctly memoize if an exception is raised,
                # so can't use executed_cmd
                expect { shell_cmd.run_command}.to raise_error(Mixlib::ShellOut::CommandTimeout)
                expect(shell_cmd.stdout).to include("nanana cant hear you")
                expect(shell_cmd.status.termsig).to eq(9)

                expect(log_output.string).to include("Command exceeded allowed execution time, sending TERM")
                expect(log_output.string).to include("Command exceeded allowed execution time, sending KILL")
              end

            end
          end

          context "and the child process forks grandchildren" do
            let(:cmd) do
              ruby_wo_shell(<<-CODE)
                STDOUT.sync = true
                trap(:TERM) { print "got term in child\n"; exit!(123) }
                fork do
                  trap(:TERM) { print "got term in grandchild\n"; exit!(142) }
                  sleep 10
                end
                sleep 10
              CODE
            end

            it "should TERM the wayward child and grandchild" do
              # note: let blocks don't correctly memoize if an exception is raised,
              # so can't use executed_cmd
              expect { shell_cmd.run_command}.to raise_error(Mixlib::ShellOut::CommandTimeout)
              expect(shell_cmd.stdout).to include("got term in child")
              expect(shell_cmd.stdout).to include("got term in grandchild")
            end

          end
          context "and the child process forks grandchildren that don't respond to TERM" do
            let(:cmd) do
              ruby_wo_shell(<<-CODE)
                STDOUT.sync = true

                trap(:TERM) { print "got term in child\n"; exit!(123) }
                fork do
                  trap(:TERM) { print "got term in grandchild\n" }
                  sleep 10
                end
                sleep 10
              CODE
            end

            it "should TERM the wayward child and grandchild, then KILL whoever is left" do
              # note: let blocks don't correctly memoize if an exception is raised,
              # so can't use executed_cmd
              expect { shell_cmd.run_command}.to raise_error(Mixlib::ShellOut::CommandTimeout)

              begin

                # A little janky. We get the process group id out of the command
                # object, then try to kill a process in it to make sure none
                # exists. Trusting the system under test like this isn't great but
                # it's difficult to test otherwise.
                child_pgid = shell_cmd.send(:child_pgid)
                initial_process_listing = `ps -j`

                expect(shell_cmd.stdout).to include("got term in child")
                expect(shell_cmd.stdout).to include("got term in grandchild")

                kill_return_val = Process.kill(:INT, child_pgid) # should raise ESRCH
                # AIX - kill returns code > 0 for error, where as other platforms return -1. Ruby code signal.c treats < 0 as error and raises exception and hence fails on AIX. So we check the return code for assertions since ruby wont raise an error here.

                if(kill_return_val == 0)
                  # Debug the failure:
                  puts "child pgid=#{child_pgid.inspect}"
                  Process.wait
                  puts "collected process: #{$?.inspect}"
                  puts "initial process listing:\n#{initial_process_listing}"
                  puts "current process listing:"
                  puts `ps -j`
                  raise "Failed to kill all expected processes"
                end
              rescue Errno::ESRCH
                # this is what we want
              end
            end

          end
        end
      end

      context 'with subprocess that exceeds buffersize' do
        let(:ruby_code) { 'print("X" * 16 * 1024); print("." * 1024)' }

        it "should still reads all of the output" do
          expect(stdout).to match(/X{16384}\.{1024}/)
        end
      end

      context 'with subprocess that returns nothing' do
        let(:ruby_code) { 'exit 0' }

        it 'should return an empty string for stdout' do
          expect(stdout).to eql('')
        end

        it 'should return an empty string for stderr' do
          expect(stderr).to eql('')
        end
      end

      context 'with subprocess that closes stdin and continues writing to stdout' do
        let(:ruby_code) { "STDIN.close; sleep 0.5; STDOUT.puts :win" }
        let(:options) { { :input => "Random data #{rand(100000)}" } }

        it 'should not hang or lose output' do
          expect(stdout).to eql("win#{LINE_ENDING}")
        end
      end

      context 'with subprocess that closes stdout and continues writing to stderr' do
        let(:ruby_code) { "STDOUT.close; sleep 0.5; STDERR.puts :win" }

        it 'should not hang or lose output' do
          expect(stderr).to eql("win#{LINE_ENDING}")
        end
      end

      context 'with subprocess that closes stderr and continues writing to stdout' do
        let(:ruby_code) { "STDERR.close; sleep 0.5; STDOUT.puts :win" }

        it 'should not hang or lose output' do
          expect(stdout).to eql("win#{LINE_ENDING}")
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
          expect(stdout).not_to be_empty
        end

        it 'should close all pipes', :unix_only do
          expect(unclosed_pipes).to be_empty
        end
      end

      context 'with subprocess reading lots of data from stdin' do
        subject { stdout.to_i }
        let(:ruby_code) { 'STDOUT.print gets.size' }
        let(:options) { { :input => input } }
        let(:input) { 'f' * 20_000 }
        let(:input_size) { input.size }

        it 'should not hang' do
          is_expected.to eql(input_size)
        end
      end

      context 'with subprocess writing lots of data to both stdout and stderr' do
        let(:expected_output_with) { lambda { |chr| (chr * 20_000) + "#{LINE_ENDING}" + (chr * 20_000) + "#{LINE_ENDING}" } }

        context 'when writing to STDOUT first' do
          let(:ruby_code) { %q{puts "f" * 20_000; STDERR.puts "u" * 20_000; puts "f" * 20_000; STDERR.puts "u" * 20_000} }

          it "should not deadlock" do
            expect(stdout).to eql(expected_output_with.call('f'))
            expect(stderr).to eql(expected_output_with.call('u'))
          end
        end

        context 'when writing to STDERR first' do
          let(:ruby_code) { %q{STDERR.puts "u" * 20_000; puts "f" * 20_000; STDERR.puts "u" * 20_000; puts "f" * 20_000} }

          it "should not deadlock" do
            expect(stdout).to eql(expected_output_with.call('f'))
            expect(stderr).to eql(expected_output_with.call('u'))
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
            expect(stdout).to eql(expected_output_with.call('f'))
            expect(stderr).to eql(expected_output_with.call('u'))
          end
        end

        context 'when writing to STDERR first' do
          let(:input) { [ 'u' * multiplier, 'f' * multiplier, 'u' * multiplier, 'f' * multiplier ].join(LINE_ENDING) }

          it "should not deadlock" do
            expect(stdout).to eql(expected_output_with.call('f'))
            expect(stderr).to eql(expected_output_with.call('u'))
          end
        end
      end

      context 'when subprocess closes prematurely', :unix_only do
        context 'with input data' do
          let(:ruby_code) { 'bad_ruby { [ } ]' }
          let(:options) { { :input => input } }
          let(:input) { [ 'f' * 20_000, 'u' * 20_000, 'f' * 20_000, 'u' * 20_000 ].join(LINE_ENDING) }

          # Should the exception be handled?
          it 'should raise error' do
            expect { executed_cmd }.to raise_error(Errno::EPIPE)
          end
        end
      end

      context 'when subprocess writes, pauses, then continues writing' do
        subject { stdout }
        let(:ruby_code) { %q{puts "before"; sleep 0.5; puts "after"} }

        it 'should not hang or lose output' do
          is_expected.to eql("before#{LINE_ENDING}after#{LINE_ENDING}")
        end
      end

      context 'when subprocess pauses before writing' do
        subject { stdout }
        let(:ruby_code) { 'sleep 0.5; puts "missed_the_bus"' }

        it 'should not hang or lose output' do
          is_expected.to eql("missed_the_bus#{LINE_ENDING}")
        end
      end

      context 'when subprocess pauses before reading from stdin' do
        subject { stdout.to_i }
        let(:ruby_code) { 'sleep 0.5; print gets.size ' }
        let(:input) { 'c' * 1024 }
        let(:input_size) { input.size }
        let(:options) { { :input => input } }

        it 'should not hang or lose output' do
          is_expected.to eql(input_size)
        end
      end

      context 'when execution fails' do
        let(:cmd) { "fuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu" }

        context 'when running under Unix', :unix_only do
          it "should recover the error message" do
            expect { executed_cmd }.to raise_error(Errno::ENOENT)
          end

          context 'with input' do
            let(:options) { {:input => input } }
            let(:input) { "Random input #{rand(1000000)}" }

            it "should recover the error message" do
              expect { executed_cmd }.to raise_error(Errno::ENOENT)
            end
          end
        end

        skip 'when running under Windows', :windows_only
      end

      context 'without input data' do
        context 'with subprocess that expects stdin' do
          let(:ruby_code) { %q{print STDIN.eof?.to_s} }

          # If we don't have anything to send to the subprocess, we need to close
          # stdin so that the subprocess won't wait for input.
          it 'should close stdin' do
            expect(stdout).to eql("true")
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
          expect(output_line).to eql(expected_output[i])
        end
      end
    end
  end

  context "when running under *nix", :requires_root, :unix_only do
    let(:cmd) { 'whoami' }
    let(:running_user) { shell_cmd.run_command.stdout.chomp }

    context "when no user is set" do
      it "should run as current user" do
        expect(running_user).to eql(ENV["USER"])
      end
    end

    context "when user is specified" do
      let(:user) { 'nobody' }

      let(:options) { { :user => user } }

      it "should run as specified user" do
        expect(running_user).to eql("#{user}")
      end
    end
  end
end
