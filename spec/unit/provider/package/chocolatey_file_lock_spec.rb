#
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe "Chocolatey File Lock Retry", :windows_only do
  let(:new_resource) { Chef::Resource::ChocolateyPackage.new("testpackage") }
  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::Package::Chocolatey.new(new_resource, run_context)
  end

  let(:choco_install_path) { "C:\\ProgramData\\chocolatey" }
  let(:choco_lib_path) { File.join(choco_install_path, "lib") }
  let(:package_dir) { File.join(choco_lib_path, "testpackage") }
  let(:pending_file) { File.join(package_dir, ".chocolateyPending") }
  let(:nupkg_file) { File.join(package_dir, "testpackage.1.0.0.nupkg") }

  before do
    allow(provider).to receive(:choco_install_path).and_return(choco_install_path)
    allow(provider).to receive(:choco_lib_path).and_return(choco_lib_path)
  end

  describe "realistic file lock scenarios" do
    context "when .chocolateyPending file is locked by chocolatey" do
      it "retries file lock operations with exponential backoff" do
        expect(Chef::Log).to receive(:debug).with("Waiting for chocolatey to release file locks for packages: testpackage")
        expect(File).to receive(:exist?).with(pending_file).and_return(true)

        # Simulate file lock being held, then released
        call_count = 0
        expect(File).to receive(:open).with(pending_file, "r").twice do |&block|
          call_count += 1
          file_mock = double
          if call_count == 1
            # First attempt fails with lock error
            expect(file_mock).to receive(:flock).with(File::LOCK_EX | File::LOCK_NB).and_raise(Errno::EAGAIN)
          else
            # Second attempt succeeds
            expect(file_mock).to receive(:flock).with(File::LOCK_EX | File::LOCK_NB).and_return(true)
          end
          block.call(file_mock)
        end

        expect(Chef::Log).to receive(:debug).with(/Chocolatey file lock detected.*retrying/)

        provider.send(:wait_for_chocolatey_lock_release, ["testpackage"])
      end

      it "eventually gives up after max retries" do
        expect(Chef::Log).to receive(:debug).with("Waiting for chocolatey to release file locks for packages: testpackage")
        expect(File).to receive(:exist?).with(pending_file).and_return(true)

        # Simulate persistent file lock
        file_mock = double
        expect(File).to receive(:open).with(pending_file, "r").exactly(6).times.and_yield(file_mock)
        expect(file_mock).to receive(:flock).with(File::LOCK_EX | File::LOCK_NB).exactly(6).times.and_raise(Errno::EAGAIN)

        expect(Chef::Log).to receive(:debug).exactly(5).times.with(/Chocolatey file lock detected.*retrying/)
        expect(Chef::Log).to receive(:warn).with(/Failed waiting.*after 5 retries/)

        expect {
          provider.send(:wait_for_chocolatey_lock_release, ["testpackage"])
        }.to raise_error(Errno::EAGAIN)
      end
    end

    context "when .nupkg files are locked during package data retrieval" do
      it "retries zip file operations when encountering access errors" do
        glob_pattern = File.join(package_dir, "*.nupkg")
        allow(File).to receive(:join).and_call_original

        call_count = 0
        expect(Dir).to receive(:glob).with(glob_pattern).twice do
          call_count += 1
          if call_count == 1
            # First attempt fails with access denied
            raise Errno::EACCES.new("The process cannot access the file because it is being used by another process")
          else
            # Second attempt succeeds
            [nupkg_file]
          end
        end

        # Mock successful zip file processing
        zip_file_mock = double
        zip_entry_mock = double(name: "testpackage.nuspec", get_input_stream: double)
        expect(Zip::File).to receive(:open).with(nupkg_file).and_yield(zip_file_mock)
        expect(zip_file_mock).to receive(:each).and_yield(zip_entry_mock)

        # Mock XML parsing
        nuspec_content = <<~XML
          <?xml version="1.0"?>
          <package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
            <metadata>
              <id>testpackage</id>
              <version>1.0.0</version>
            </metadata>
          </package>
        XML
        expect(zip_entry_mock.get_input_stream).to receive(:read).and_return(nuspec_content)
        expect(zip_entry_mock.get_input_stream).to receive(:close)

        expect(Chef::Log).to receive(:debug).with(/Chocolatey file lock detected.*retrying/)

        result = provider.send(:get_pkg_data, package_dir)
        expect(result).to eq({ "testpackage" => "1.0.0" })
      end
    end

    context "when directory listing fails due to file locks" do
      it "retries directory operations" do
        expect(Dir).to receive(:exist?).with(choco_lib_path).and_return(true)

        call_count = 0
        expect(Dir).to receive(:entries).with(choco_lib_path).twice do
          call_count += 1
          if call_count == 1
            # First attempt fails with busy error
            raise Errno::EBUSY.new("Resource temporarily unavailable")
          else
            # Second attempt succeeds
            [".", "..", "chocolatey", "testpackage"]
          end
        end

        # Mock File.directory? and File.join calls
        allow(File).to receive(:join).and_call_original
        allow(File).to receive(:directory?).and_call_original
        expect(File).to receive(:directory?).with(File.join(choco_lib_path, "chocolatey")).and_return(true)
        expect(File).to receive(:directory?).with(File.join(choco_lib_path, "testpackage")).and_return(true)

        expect(Chef::Log).to receive(:debug).with(/Chocolatey file lock detected.*retrying/)

        result = provider.send(:get_local_pkg_dirs, choco_lib_path)
        expect(result).to eq(%w{chocolatey testpackage})
      end
    end
  end

  describe "error message detection" do
    [
      "The process cannot access the file 'C:\\ProgramData\\chocolatey\\lib\\package\\.chocolateyPending' because it is being used by another process",
      "Cannot access file because it is being used by another process",
      "Access to chocolateyPending file denied",
    ].each do |error_message|
      it "correctly identifies '#{error_message}' as a file lock error" do
        error = StandardError.new(error_message)
        expect(provider.send(:file_lock_error?, error)).to be true
      end
    end

    it "correctly identifies Errno::EBUSY as a file lock error" do
      error = Errno::EBUSY.new("Resource temporarily unavailable")
      expect(provider.send(:file_lock_error?, error)).to be true
    end

    [
      "Package not found",
      "Network timeout",
      "Invalid package format",
    ].each do |error_message|
      it "correctly identifies '#{error_message}' as NOT a file lock error" do
        error = StandardError.new(error_message)
        expect(provider.send(:file_lock_error?, error)).to be false
      end
    end
  end

  describe "exponential backoff timing" do
    it "uses correct delay intervals" do
      call_count = 0

      expect(provider).to receive(:sleep).with(0.5)  # First retry: base_delay * 2^0
      expect(provider).to receive(:sleep).with(1.0)  # Second retry: base_delay * 2^1
      expect(provider).to receive(:sleep).with(2.0)  # Third retry: base_delay * 2^2

      expect {
        provider.send(:with_file_lock_retry, "test operation", max_retries: 3, base_delay: 0.5) do
          call_count += 1
          raise Errno::EACCES.new # Always fail to exhaust retries
        end
      }.to raise_error(Errno::EACCES)

      expect(call_count).to eq(4) # Initial try + 3 retries
    end
  end
end
