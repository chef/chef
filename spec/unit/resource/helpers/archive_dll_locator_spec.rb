require "spec_helper"
require "chef/resource/helpers/archive_dll_locator"

describe Chef::ResourceHelpers::ArchiveDllLocator do
  let(:locator) { described_class }
  let(:ok_status) { instance_double(Process::Status, success?: true) }
  let(:fail_status) { instance_double(Process::Status, success?: false) }
  let(:source_file) { "/hab/pkgs/chef/chef-infra-client/19.4.45/2026/vendor/gems/chef/lib/chef/resource/archive_file.rb" }
  let(:env_dll) { "/hab/pkgs/core/libarchive/3.7.0/1/bin/archive.dll" }
  let(:cli_dll) { "/hab/pkgs/core/libarchive/3.8.0/2/bin/archive.dll" }

  describe ".find" do
    it "prefers RUBY_DLL_PATH over the hab CLI and the search" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(env_dll).and_return(true)
      expect(Open3).not_to receive(:capture3)
      expect(Dir).not_to receive(:glob)
      env = { "RUBY_DLL_PATH" => "\\hab\\pkgs\\core\\libarchive\\3.7.0\\1\\bin" }
      expect(locator.find(source_file: source_file, env: env)).to eq(env_dll)
    end

    it "uses the hab CLI when RUBY_DLL_PATH has no archive.dll, before searching" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(cli_dll).and_return(true)
      allow(Open3).to receive(:capture3).with("hab pkg path core/libarchive")
        .and_return(["\\hab\\pkgs\\core\\libarchive\\3.8.0\\2\n", "", ok_status])
      expect(Dir).not_to receive(:glob)
      expect(locator.find(source_file: source_file, env: {})).to eq(cli_dll)
    end

    it "searches the hab root only after RUBY_DLL_PATH and the hab CLI fail" do
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
      expect(Dir).to receive(:glob)
        .with("/hab/pkgs/core/libarchive/*/*/bin/archive.dll").and_return([env_dll])
      expect(locator.find(source_file: source_file, env: {})).to eq(env_dll)
    end

    it "returns nil when nothing is found" do
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
      allow(Dir).to receive(:glob).and_return([])
      expect(locator.find(source_file: source_file, env: {})).to be_nil
    end
  end

  describe ".from_ruby_dll_path" do
    it "skips empty entries and directories without the dll" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/nope/archive.dll").and_return(false)
      sep = File::PATH_SEPARATOR
      expect(locator.from_ruby_dll_path({ "RUBY_DLL_PATH" => "#{sep}\\nope" })).to be_nil
    end

    it "returns nil when RUBY_DLL_PATH is unset" do
      expect(locator.from_ruby_dll_path({})).to be_nil
    end
  end

  describe ".from_hab_cli" do
    it "returns nil when the command fails" do
      allow(Open3).to receive(:capture3).and_return(["", "boom", fail_status])
      expect(locator.from_hab_cli).to be_nil
    end

    it "returns nil when hab is not installed" do
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
      expect(locator.from_hab_cli).to be_nil
    end

    it "returns nil when the reported package has no archive.dll" do
      allow(Open3).to receive(:capture3).and_return(["\\missing\n", "", ok_status])
      expect(locator.from_hab_cli).to be_nil
    end
  end

  describe ".from_hab_root_search" do
    it "returns nil when the source file is not under a hab root" do
      expect(Dir).not_to receive(:glob)
      expect(locator.from_hab_root_search("/opt/chef/lib/archive_file.rb")).to be_nil
    end

    it "returns the highest-sorting match" do
      older = "/hab/pkgs/core/libarchive/3.7.0/1/bin/archive.dll"
      allow(Dir).to receive(:glob).and_return([older, cli_dll])
      expect(locator.from_hab_root_search(source_file)).to eq(cli_dll)
    end
  end
end
