require 'spec_helper'

describe 'Mixlib::ShellOut::Windows', :windows_only do

  describe 'Utils' do
    describe '.should_run_under_cmd?' do
      subject { Mixlib::ShellOut::Windows::Utils.should_run_under_cmd?(command) }

      def self.with_command(_command, &example)
        context "with command: #{_command}" do
          let(:command) { _command }
          it(&example)
        end
      end

      context 'when unquoted' do
        with_command(%q{ruby -e 'prints "foobar"'}) { is_expected.not_to be_truthy }

        # https://github.com/opscode/mixlib-shellout/pull/2#issuecomment-4825574
        with_command(%q{"C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Bin\NETFX 4.0 Tools\gacutil.exe" /i "C:\Program Files (x86)\NUnit 2.6\bin\framework\nunit.framework.dll"}) { is_expected.not_to be_truthy }

        with_command(%q{ruby -e 'exit 1' | ruby -e 'exit 0'}) { is_expected.to be_truthy }
        with_command(%q{ruby -e 'exit 1' > out.txt}) { is_expected.to be_truthy }
        with_command(%q{ruby -e 'exit 1' > out.txt 2>&1}) { is_expected.to be_truthy }
        with_command(%q{ruby -e 'exit 1' < in.txt}) { is_expected.to be_truthy }
        with_command(%q{ruby -e 'exit 1' || ruby -e 'exit 0'}) { is_expected.to be_truthy }
        with_command(%q{ruby -e 'exit 1' && ruby -e 'exit 0'}) { is_expected.to be_truthy }
        with_command(%q{@echo TRUE}) { is_expected.to be_truthy }

        with_command(%q{echo %PATH%}) { is_expected.to be_truthy }
        with_command(%q{run.exe %A}) { is_expected.to be_falsey }
        with_command(%q{run.exe B%}) { is_expected.to be_falsey }
        with_command(%q{run.exe %A B%}) { is_expected.to be_falsey }
        with_command(%q{run.exe %A B% %PATH%}) { is_expected.to be_truthy }
        with_command(%q{run.exe %A B% %_PATH%}) { is_expected.to be_truthy }
        with_command(%q{run.exe %A B% %PATH_EXT%}) { is_expected.to be_truthy }
        with_command(%q{run.exe %A B% %1%}) { is_expected.to be_falsey }
        with_command(%q{run.exe %A B% %PATH1%}) { is_expected.to be_truthy }
        with_command(%q{run.exe %A B% %_PATH1%}) { is_expected.to be_truthy }

        context 'when outside quotes' do
          with_command(%q{ruby -e "exit 1" | ruby -e "exit 0"}) { is_expected.to be_truthy }
          with_command(%q{ruby -e "exit 1" > out.txt}) { is_expected.to be_truthy }
          with_command(%q{ruby -e "exit 1" > out.txt 2>&1}) { is_expected.to be_truthy }
          with_command(%q{ruby -e "exit 1" < in.txt}) { is_expected.to be_truthy }
          with_command(%q{ruby -e "exit 1" || ruby -e "exit 0"}) { is_expected.to be_truthy }
          with_command(%q{ruby -e "exit 1" && ruby -e "exit 0"}) { is_expected.to be_truthy }
          with_command(%q{@echo "TRUE"}) { is_expected.to be_truthy }

          context 'with unclosed quote' do
            with_command(%q{ruby -e "exit 1" | ruby -e "exit 0}) { is_expected.to be_truthy }
            with_command(%q{ruby -e "exit 1" > "out.txt}) { is_expected.to be_truthy }
            with_command(%q{ruby -e "exit 1" > "out.txt 2>&1}) { is_expected.to be_truthy }
            with_command(%q{ruby -e "exit 1" < "in.txt}) { is_expected.to be_truthy }
            with_command(%q{ruby -e "exit 1" || "ruby -e "exit 0"}) { is_expected.to be_truthy }
            with_command(%q{ruby -e "exit 1" && "ruby -e "exit 0"}) { is_expected.to be_truthy }
            with_command(%q{@echo "TRUE}) { is_expected.to be_truthy }

            with_command(%q{echo "%PATH%}) { is_expected.to be_truthy }
            with_command(%q{run.exe "%A}) { is_expected.to be_falsey }
            with_command(%q{run.exe "B%}) { is_expected.to be_falsey }
            with_command(%q{run.exe "%A B%}) { is_expected.to be_falsey }
            with_command(%q{run.exe "%A B% %PATH%}) { is_expected.to be_truthy }
            with_command(%q{run.exe "%A B% %_PATH%}) { is_expected.to be_truthy }
            with_command(%q{run.exe "%A B% %PATH_EXT%}) { is_expected.to be_truthy }
            with_command(%q{run.exe "%A B% %1%}) { is_expected.to be_falsey }
            with_command(%q{run.exe "%A B% %PATH1%}) { is_expected.to be_truthy }
            with_command(%q{run.exe "%A B% %_PATH1%}) { is_expected.to be_truthy }
          end
        end
      end

      context 'when quoted' do
        with_command(%q{run.exe "ruby -e 'exit 1' || ruby -e 'exit 0'"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "ruby -e 'exit 1' > out.txt"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "ruby -e 'exit 1' > out.txt 2>&1"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "ruby -e 'exit 1' < in.txt"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "ruby -e 'exit 1' || ruby -e 'exit 0'"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "ruby -e 'exit 1' && ruby -e 'exit 0'"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "%PATH%"}) { is_expected.to be_truthy }
        with_command(%q{run.exe "%A"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "B%"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "%A B%"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "%A B% %PATH%"}) { is_expected.to be_truthy }
        with_command(%q{run.exe "%A B% %_PATH%"}) { is_expected.to be_truthy }
        with_command(%q{run.exe "%A B% %PATH_EXT%"}) { is_expected.to be_truthy }
        with_command(%q{run.exe "%A B% %1%"}) { is_expected.to be_falsey }
        with_command(%q{run.exe "%A B% %PATH1%"}) { is_expected.to be_truthy }
        with_command(%q{run.exe "%A B% %_PATH1%"}) { is_expected.to be_truthy }

        context 'with unclosed quote' do
          with_command(%q{run.exe "ruby -e 'exit 1' || ruby -e 'exit 0'}) { is_expected.to be_falsey }
          with_command(%q{run.exe "ruby -e 'exit 1' > out.txt}) { is_expected.to be_falsey }
          with_command(%q{run.exe "ruby -e 'exit 1' > out.txt 2>&1}) { is_expected.to be_falsey }
          with_command(%q{run.exe "ruby -e 'exit 1' < in.txt}) { is_expected.to be_falsey }
          with_command(%q{run.exe "ruby -e 'exit 1' || ruby -e 'exit 0'}) { is_expected.to be_falsey }
          with_command(%q{run.exe "ruby -e 'exit 1' && ruby -e 'exit 0'}) { is_expected.to be_falsey }
          with_command(%q{run.exe "%PATH%}) { is_expected.to be_truthy }
          with_command(%q{run.exe "%A}) { is_expected.to be_falsey }
          with_command(%q{run.exe "B%}) { is_expected.to be_falsey }
          with_command(%q{run.exe "%A B%}) { is_expected.to be_falsey }
          with_command(%q{run.exe "%A B% %PATH%}) { is_expected.to be_truthy }
          with_command(%q{run.exe "%A B% %_PATH%}) { is_expected.to be_truthy }
          with_command(%q{run.exe "%A B% %PATH_EXT%}) { is_expected.to be_truthy }
          with_command(%q{run.exe "%A B% %1%}) { is_expected.to be_falsey }
          with_command(%q{run.exe "%A B% %PATH1%}) { is_expected.to be_truthy }
          with_command(%q{run.exe "%A B% %_PATH1%}) { is_expected.to be_truthy }
        end
      end
    end

    describe '.kill_process_tree' do
      let(:utils) { Mixlib::ShellOut::Windows::Utils }
      let(:wmi) { Object.new }
      let(:wmi_ole_object) { Object.new }
      let(:wmi_process) { Object.new }
      let(:logger) { Object.new }

      before do
        allow(wmi).to receive(:query).and_return([wmi_process])
        allow(wmi_process).to receive(:wmi_ole_object).and_return(wmi_ole_object)
        allow(logger).to receive(:debug)
      end

      context 'with a protected system process in the process tree' do
        before do
          allow(wmi_ole_object).to receive(:name).and_return('csrss.exe')
          allow(wmi_ole_object).to receive(:processid).and_return(100)
        end

        it 'does not attempt to kill csrss.exe' do
          expect(utils).to_not receive(:kill_process)
          utils.kill_process_tree(200, wmi, logger)
        end
      end

      context 'with a non-system-critical process in the process tree' do
        before do
          allow(wmi_ole_object).to receive(:name).and_return('blah.exe')
          allow(wmi_ole_object).to receive(:processid).and_return(300)
        end

        it 'does attempt to kill blah.exe' do
          expect(utils).to receive(:kill_process).with(wmi_process, logger)
          expect(utils).to receive(:kill_process_tree).with(200, wmi, logger).and_call_original
          expect(utils).to receive(:kill_process_tree).with(300, wmi, logger)
          utils.kill_process_tree(200, wmi, logger)
        end
      end
    end
  end

  # Caveat: Private API methods are subject to change without notice.
  # Monkeypatch at your own risk.
  context 'for private API methods' do

    describe '::IS_BATCH_FILE' do
      subject { candidate =~ Mixlib::ShellOut::Windows::IS_BATCH_FILE }

      def self.with_candidate(_context, _options = {}, &example)
        context "with #{_context}" do
          let(:candidate) { _options[:candidate] }
          it(&example)
        end
      end

      with_candidate('valid .bat file', :candidate => 'autoexec.bat') { is_expected.to be_truthy }
      with_candidate('valid .cmd file', :candidate => 'autoexec.cmd') { is_expected.to be_truthy }
      with_candidate('valid quoted .bat file', :candidate => '"C:\Program Files\autoexec.bat"') { is_expected.to be_truthy }
      with_candidate('valid quoted .cmd file', :candidate => '"C:\Program Files\autoexec.cmd"') { is_expected.to be_truthy }

      with_candidate('invalid .bat file', :candidate => 'autoexecbat') { is_expected.not_to be_truthy }
      with_candidate('invalid .cmd file', :candidate => 'autoexeccmd') { is_expected.not_to be_truthy }
      with_candidate('bat in filename', :candidate => 'abattoir.exe') { is_expected.not_to be_truthy }
      with_candidate('cmd in filename', :candidate => 'parse_cmd.exe') { is_expected.not_to be_truthy }

      with_candidate('invalid quoted .bat file', :candidate => '"C:\Program Files\autoexecbat"') { is_expected.not_to be_truthy }
      with_candidate('invalid quoted .cmd file', :candidate => '"C:\Program Files\autoexeccmd"') { is_expected.not_to be_truthy }
      with_candidate('quoted bat in filename', :candidate => '"C:\Program Files\abattoir.exe"') { is_expected.not_to be_truthy }
      with_candidate('quoted cmd in filename', :candidate => '"C:\Program Files\parse_cmd.exe"') { is_expected.not_to be_truthy }
    end

    describe '#command_to_run' do
      subject { stubbed_shell_out.send(:command_to_run, cmd) }

      let(:stubbed_shell_out) { fail NotImplemented, 'Must declare let(:stubbed_shell_out)' }
      let(:shell_out) { Mixlib::ShellOut.new(cmd) }

      let(:utils) { Mixlib::ShellOut::Windows::Utils }
      let(:with_valid_exe_at_location) { lambda { |s| allow(utils).to receive(:find_executable).and_return(executable_path) } }
      let(:with_invalid_exe_at_location) { lambda { |s| allow(utils).to receive(:find_executable).and_return(nil) } }

      context 'with empty command' do
        let(:stubbed_shell_out) { shell_out }
        let(:cmd) { ' ' }

        it 'should return with a nil executable' do
          is_expected.to eql([nil, cmd])
        end
      end

      context 'with extensionless executable' do
        let(:stubbed_shell_out) { shell_out }
        let(:executable_path) { 'C:\Windows\system32/ping.EXE' }
        let(:cmd) { 'ping' }

        before do
          allow(ENV).to receive(:[]).with('PATH').and_return('C:\Windows\system32')
          allow(ENV).to receive(:[]).with('PATHEXT').and_return('.EXE')
          allow(ENV).to receive(:[]).with('COMSPEC').and_return('C:\Windows\system32\cmd.exe')
          allow(File).to receive(:executable?).and_return(false)
          allow(File).to receive(:executable?).with(executable_path).and_return(true)
          allow(File).to receive(:directory?).and_return(false)
        end

        it 'should return with full path with extension' do
          is_expected.to eql([executable_path, cmd])
        end

        context 'there is a directory named after command' do
          before do
            # File.executable? returns true for directories
            allow(File).to receive(:executable?).with(cmd).and_return(true)
            allow(File).to receive(:directory?).with(cmd).and_return(true)
          end

          it 'should return with full path with extension' do
            is_expected.to eql([executable_path, cmd])
          end
        end
      end

      context 'with batch files' do
        let(:stubbed_shell_out) { shell_out.tap(&with_valid_exe_at_location) }
        let(:cmd_invocation) { "cmd /c \"#{cmd}\"" }
        let(:cmd_exe) { "C:\\Windows\\system32\\cmd.exe" }
        let(:cmd) { "#{executable_path}" }

        before { ENV['ComSpec'] = 'C:\Windows\system32\cmd.exe' }

        context 'with .bat file' do
          let(:executable_path) { '"C:\Program Files\Application\Start.bat"' }

          # Examples taken from: https://github.com/opscode/mixlib-shellout/pull/2#issuecomment-4825574
          context 'with executable path enclosed in double quotes' do

            it 'should use specified batch file' do
              is_expected.to eql([cmd_exe, cmd_invocation])
            end

            context 'with arguments' do
              let(:cmd) { "#{executable_path} arguments" }

              it 'should use specified executable' do
                is_expected.to eql([cmd_exe, cmd_invocation])
              end
            end

            context 'with quoted arguments' do
              let(:cmd) { "#{executable_path} /i \"C:\Program Files (x86)\NUnit 2.6\bin\framework\nunit.framework.dll\"" }

              it 'should use specified executable' do
                is_expected.to eql([cmd_exe, cmd_invocation])
              end
            end
          end
        end

        context 'with .cmd file' do
          let(:executable_path) { '"C:\Program Files\Application\Start.cmd"' }

          # Examples taken from: https://github.com/opscode/mixlib-shellout/pull/2#issuecomment-4825574
          context 'with executable path enclosed in double quotes' do

            it 'should use specified batch file' do
              is_expected.to eql([cmd_exe, cmd_invocation])
            end

            context 'with arguments' do
              let(:cmd) { "#{executable_path} arguments" }

              it 'should use specified executable' do
                is_expected.to eql([cmd_exe, cmd_invocation])
              end
            end

            context 'with quoted arguments' do
              let(:cmd) { "#{executable_path} /i \"C:\Program Files (x86)\NUnit 2.6\bin\framework\nunit.framework.dll\"" }

              it 'should use specified executable' do
                is_expected.to eql([cmd_exe, cmd_invocation])
              end
            end
          end

        end
      end

      context 'with valid executable at location' do
        let(:stubbed_shell_out) { shell_out.tap(&with_valid_exe_at_location) }

        context 'with executable path' do
          let(:cmd) { "#{executable_path}" }
          let(:executable_path) { 'C:\RUBY192\bin\ruby.exe' }

          it 'should use specified executable' do
            is_expected.to eql([executable_path, cmd])
          end

          context 'with arguments' do
            let(:cmd) { "#{executable_path} arguments" }

            it 'should use specified executable' do
              is_expected.to eql([executable_path, cmd])
            end
          end

          context 'with quoted arguments' do
            let(:cmd) { "#{executable_path} -e \"print 'fee fie foe fum'\"" }

            it 'should use specified executable' do
              is_expected.to eql([executable_path, cmd])
            end
          end
        end

        # Examples taken from: https://github.com/opscode/mixlib-shellout/pull/2#issuecomment-4825574
        context 'with executable path enclosed in double quotes' do
          let(:cmd) { "#{executable_path}" }
          let(:executable_path) { '"C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Bin\NETFX 4.0 Tools\gacutil.exe"' }

          it 'should use specified executable' do
            is_expected.to eql([executable_path, cmd])
          end

          context 'with arguments' do
            let(:cmd) { "#{executable_path} arguments" }

            it 'should use specified executable' do
              is_expected.to eql([executable_path, cmd])
            end
          end

          context 'with quoted arguments' do
            let(:cmd) { "#{executable_path} /i \"C:\Program Files (x86)\NUnit 2.6\bin\framework\nunit.framework.dll\"" }

            it 'should use specified executable' do
              is_expected.to eql([executable_path, cmd])
            end
          end
        end

      end
    end
  end
end
