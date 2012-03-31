require 'spec_helper'

describe Mixlib::ShellOut::Windows, :windows_only => true do

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

      with_candidate('valid .bat file', :candidate => 'autoexec.bat') { should be_true }
      with_candidate('valid .cmd file', :candidate => 'autoexec.cmd') { should be_true }
      with_candidate('valid quoted .bat file', :candidate => '"C:\Program Files\autoexec.bat"') { should be_true }
      with_candidate('valid quoted .cmd file', :candidate => '"C:\Program Files\autoexec.cmd"') { should be_true }
    end

    describe '#command_to_run' do
      subject { stubbed_shell_out.send(:command_to_run, cmd) }

      let(:stubbed_shell_out) { fail NotImplemented, 'Must declare let(:stubbed_shell_out)' }
      let(:shell_out) { Mixlib::ShellOut.new(cmd) }

      let(:with_valid_exe_at_location) { lambda { |s| s.stub!(:find_exe_at_location).and_return(executable_path) } }
      let(:with_invalid_exe_at_location) { lambda { |s| s.stub!(:find_exe_at_location).and_return(nil) } }

      context 'with batch files' do
        let(:stubbed_shell_out) { shell_out.tap(&with_valid_exe_at_location) }
        let(:cmd_invocation) { "cmd /c \"#{cmd}\"" }
        let(:cmd_exe) { "C:\\Windows\\system32\\cmd.exe" }
        let(:cmd) { "#{executable_path}" }

        context 'with .bat file' do
          let(:executable_path) { '"C:\Program Files\Application\Start.bat"' }

          # Examples taken from: https://github.com/opscode/mixlib-shellout/pull/2#issuecomment-4825574
          context 'with executable path enclosed in double quotes' do

            it 'should use specified batch file' do
              should eql([cmd_exe, cmd_invocation])
            end

            context 'with arguments' do
              let(:cmd) { "#{executable_path} arguments" }

              it 'should use specified executable' do
                should eql([cmd_exe, cmd_invocation])
              end
            end

            context 'with quoted arguments' do
              let(:cmd) { "#{executable_path} /i \"C:\Program Files (x86)\NUnit 2.6\bin\framework\nunit.framework.dll\"" }

              it 'should use specified executable' do
                should eql([cmd_exe, cmd_invocation])
              end
            end
          end
        end

        context 'with .cmd file' do
          let(:executable_path) { '"C:\Program Files\Application\Start.cmd"' }

          # Examples taken from: https://github.com/opscode/mixlib-shellout/pull/2#issuecomment-4825574
          context 'with executable path enclosed in double quotes' do

            it 'should use specified batch file' do
              should eql([cmd_exe, cmd_invocation])
            end

            context 'with arguments' do
              let(:cmd) { "#{executable_path} arguments" }

              it 'should use specified executable' do
                should eql([cmd_exe, cmd_invocation])
              end
            end

            context 'with quoted arguments' do
              let(:cmd) { "#{executable_path} /i \"C:\Program Files (x86)\NUnit 2.6\bin\framework\nunit.framework.dll\"" }

              it 'should use specified executable' do
                should eql([cmd_exe, cmd_invocation])
              end
            end
          end

        end
      end

      context 'with valid executable at location' do
        let(:stubbed_shell_out) { shell_out.tap(&with_valid_exe_at_location) }

        # Examples taken from: https://github.com/opscode/mixlib-shellout/pull/2#issuecomment-4825574
        context 'with executable path enclosed in double quotes' do
          let(:cmd) { "#{executable_path}" }
          let(:executable_path) { '"C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Bin\NETFX 4.0 Tools\gacutil.exe"' }

          it 'should use specified executable' do
            should eql([executable_path, cmd])
          end

          context 'with arguments' do
            let(:cmd) { "#{executable_path} arguments" }

            it 'should use specified executable' do
              should eql([executable_path, cmd])
            end
          end

          context 'with quoted arguments' do
            let(:cmd) { "#{executable_path} /i \"C:\Program Files (x86)\NUnit 2.6\bin\framework\nunit.framework.dll\"" }

            it 'should use specified executable' do
              should eql([executable_path, cmd])
            end
          end
        end

      end
    end
  end
end
