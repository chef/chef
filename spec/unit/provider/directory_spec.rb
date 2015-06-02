#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'spec_helper'
require 'tmpdir'

describe Chef::Provider::Directory do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:tmp_dir_array) { Array.new(2) { Dir.mktmpdir } }
  let(:new_resource) { Chef::Resource::Directory.new(tmp_dir) }
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:directory) { Chef::Provider::Directory.new(new_resource, run_context) }

  describe "#load_current_resource" do
    describe "scanning file security metadata"
    describe "on unix", unix_only: true do
      describe "when the directory exists" do
        let(:dir_stat) { File::Stat.new(tmp_dir) }
        let(:expected_uid) { dir_stat.uid }
        let(:expected_gid) { dir_stat.gid }
        let(:expected_mode) { "0%o" % ( dir_stat.mode & 007777 ) }
        let(:expected_pwnam) { Etc.getpwuid(expected_uid).name }
        let(:expected_grnam) { Etc.getgrgid(expected_gid).name }

        it "describes the access mode as a String of octal integers" do
          directory.load_current_resource
          expect(directory.current_resource.mode).to eq(expected_mode)
        end

        it "when the new_resource.owner is numeric, describes the owner as a numeric uid" do
          new_resource.owner(500)
          directory.load_current_resource
          expect(directory.current_resource.owner).to eql(expected_uid)
        end

        it "when the new_resource.group is numeric, describes the group as a numeric gid" do
          new_resource.group(500)
          directory.load_current_resource
          expect(directory.current_resource.group).to eql(expected_gid)
        end

        it "when the new_resource.owner is a string, describes the owner as a string" do
          new_resource.owner("foo")
          directory.load_current_resource
          expect(directory.current_resource.owner).to eql(expected_pwnam)
        end

        it "when the new_resource.group is a string, describes the group as a string" do
          new_resource.group("bar")
          directory.load_current_resource
          expect(directory.current_resource.group).to eql(expected_grnam)
        end
      end
    end

    describe "on windows", windows_only: true do
      describe "when the directory exists" do
        it "the mode is always nil" do
          directory.load_current_resource
          expect(directory.current_resource.mode).to be nil
        end

        it "the owner is always nil" do
          directory.load_current_resource
          expect(directory.current_resource.owner).to be nil
        end

        it "the group is always nil" do
          directory.load_current_resource
          expect(directory.current_resource.group).to be nil
        end

        it "rights are always nil (incorrectly)" do
          directory.load_current_resource
          expect(directory.current_resource.rights).to be nil
        end

        it "inherits is always nil (incorrectly)" do
          directory.load_current_resource
          expect(directory.current_resource.inherits).to be nil
        end
      end
    end

    describe "when the directory does not exist" do
      before do
        FileUtils.rmdir tmp_dir
      end

      it "sets the mode, group and owner to nil" do
        directory.load_current_resource
        expect(directory.current_resource.mode).to eq(nil)
        expect(directory.current_resource.group).to eq(nil)
        expect(directory.current_resource.owner).to eq(nil)
      end
    end

  end

  describe "#define_resource_requirements" do
    describe "on unix", unix_only: true do
      it "raises an exception if the user does not exist" do
        new_resource.owner("arglebargle_iv")
        expect(Etc).to receive(:getpwnam).with("arglebargle_iv").and_raise(ArgumentError)
        directory.action = :create
        directory.load_current_resource
        expect(directory.access_controls).to receive(:define_resource_requirements).and_call_original
        directory.define_resource_requirements
        expect { directory.process_resource_requirements }.to raise_error(ArgumentError)
      end

      it "raises an exception if the group does not exist" do
        new_resource.group("arglebargle_iv")
        expect(Etc).to receive(:getgrnam).with("arglebargle_iv").and_raise(ArgumentError)
        directory.action = :create
        directory.load_current_resource
        expect(directory.access_controls).to receive(:define_resource_requirements).and_call_original
        directory.define_resource_requirements
        expect { directory.process_resource_requirements }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#run_action(:create)" do
    describe "when the path is a string" do
      describe "and the directory exists" do
        it "does not create the directory" do
          expect(Dir).not_to receive(:mkdir).with(new_resource.path)
          directory.run_action(:create)
        end

        it "should not set the resource as updated" do
          directory.run_action(:create)
          expect(new_resource).not_to be_updated
        end
      end

      describe "and the directory does not exist" do
        before do
          FileUtils.rmdir tmp_dir
        end

        it "creates the directory" do
          directory.run_action(:create)
          expect(File.exist?(tmp_dir)).to be true
        end

        it "sets the new resource as updated" do
          directory.run_action(:create)
          expect(new_resource).to be_updated
        end
      end

      describe "and the parent directory does not exist" do
        before do
          new_resource.path "#{tmp_dir}/foobar"
          FileUtils.rmdir tmp_dir
        end

        it "raises an exception when recursive is false" do
          new_resource.recursive false
          expect { directory.run_action(:create) }.to raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
        end

        it "creates the directories when recursive is true" do
          new_resource.recursive true
          directory.run_action(:create)
          expect(new_resource).to be_updated
          expect(File.exist?("#{tmp_dir}/foobar")).to be true
        end

        it "raises an exception when the parent directory is a file and recursive is true" do
          FileUtils.touch tmp_dir
          new_resource.recursive true
          expect { directory.run_action(:create) }.to raise_error
        end

        it "raises the right exception when the parent directory is a file and recursive is true" do
          pending "this seems to return the wrong error"  # FIXME
          FileUtils.touch tmp_dir
          new_resource.recursive true
          expect { directory.run_action(:create) }.to raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
        end
      end
    end

    describe "when the path is an array" do
      before do
        new_resource.name 'Array of directories'
        new_resource.path tmp_dir_array
      end

      describe "and both directories exist" do
        it "does not create any directories" do
          tmp_dir_array.each { |d| expect(Dir).not_to receive(:mkdir).with(d) }
          directory.run_action(:create)
        end

        it "should not set the resource as updated" do
          directory.run_action(:create)
          expect(new_resource).not_to be_updated
        end
      end

      describe "and only one directory exists" do
        before do
          FileUtils.rmdir tmp_dir_array.first
        end

        it "creates the missing directory" do
          directory.run_action(:create)
          File.exist?(tmp_dir_array.first)
        end

        it "sets the new resource as updated" do
          directory.run_action(:create)
          expect(new_resource).to be_updated
        end
      end

      describe "and neither directory exists" do
        before do
          tmp_dir_array.each { |d| FileUtils.rmdir d }
        end

        it "creates two directories" do
          directory.run_action(:create)
          tmp_dir_array.each do |dir|
            expect(File.exist?(dir)).to be true
          end
        end

        it "sets the new resource as updated" do
          directory.run_action(:create)
          expect(new_resource).to be_updated
        end
      end

      describe "and the parent directory does not exist" do
        before do
          new_resource.path tmp_dir_array.map { |d| "#{d}/foobar" }
          tmp_dir_array.each { |d| FileUtils.rmdir d }
        end

        it "raises an exception when recursive is false" do
          new_resource.recursive false
          expect { directory.run_action(:create) }.to raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
        end

        it "creates the directories when recursive is true" do
          new_resource.recursive true
          directory.run_action(:create)
          expect(new_resource).to be_updated
          tmp_dir_array.map { |d| "#{d}/foobar" }.each do |dir|
            expect(File.exist?(dir)).to be true
          end
        end

        it "raises an exception when the parent directory is a file and recursive is true" do
          tmp_dir_array.each { |d| FileUtils.touch d }
          new_resource.recursive true
          expect { directory.run_action(:create) }.to raise_error
        end

        it "raises the right exception when the parent directory is a file and recursive is true" do
          pending "this seems to return the wrong error"  # FIXME
          FileUtils.touch tmp_dir
          new_resource.recursive true
          expect { directory.run_action(:create) }.to raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
        end
      end

      describe "and one parent directory does not exist" do
        before do
          new_resource.path tmp_dir_array.map { |d| "#{d}/foobar" }
          FileUtils.rmdir tmp_dir_array.first
        end

        it "raises an exception when recursive is false" do
          new_resource.recursive false
          expect { directory.run_action(:create) }.to raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
        end

        it "creates the directories when recursive is true" do
          new_resource.recursive true
          directory.run_action(:create)
          expect(new_resource).to be_updated
          tmp_dir_array.map { |d| "#{d}/foobar" }.each do |dir|
            expect(File.exist?(dir)).to be true
          end
        end

        it "raises an exception when one parent directory is a file and recursive is true" do
          FileUtils.touch tmp_dir_array.first
          new_resource.recursive true
          expect { directory.run_action(:create) }.to raise_error
        end
      end
    end
  end

  describe "#run_action(:delete)" do
    describe "when the path is a string" do
      describe "and the directory exists" do
        it "deletes the directory" do
          directory.run_action(:delete)
          expect(File.exist?(tmp_dir)).to be false
        end

        it "sets the new resource as updated" do
          directory.run_action(:delete)
          expect(new_resource).to be_updated
        end
      end

      describe "and the directory does not exist" do
        before do
          FileUtils.rmdir tmp_dir
        end

        it "does not delete the directory" do
          expect(Dir).not_to receive(:delete).with(new_resource.path)
          directory.run_action(:delete)
        end

        it "does nto set the new resource as updated" do
          directory.run_action(:delete)
          expect(new_resource).not_to be_updated
        end
      end

      describe "and the directory is not writable" do
        before do
          allow(Chef::FileAccessControl).to receive(:writable?).and_return(false)
        end

        it "cannot delete it and raises an exception" do
          expect { directory.run_action(:delete) }.to raise_error(RuntimeError)
        end
      end

      describe "and the target directory is a file" do
        before do
          FileUtils.rmdir tmp_dir
          FileUtils.touch tmp_dir
        end

        it "cannot delete it and raises an exception" do
          expect { directory.run_action(:delete) }.to raise_error(RuntimeError)
        end
      end
    end

    describe "when the path is an array" do
      before do
        new_resource.name 'Array of directories'
        new_resource.path tmp_dir_array
      end

      describe "and both directories exist" do
        it "deletes both directories" do
          directory.run_action(:delete)
          tmp_dir_array.each do |dir|
            expect(File.exist?(dir)).to be false
          end
        end

        it "sets the new resource as updated" do
          directory.run_action(:delete)
          expect(new_resource).to be_updated
        end
      end

      describe "and neither directory exists" do
        before do
          tmp_dir_array.each { |d| FileUtils.rmdir d }
        end

        it "does not delete the directory" do
          tmp_dir_array.each { |d| expect(Dir).not_to receive(:delete).with(d) }
          directory.run_action(:delete)
        end

        it "does not set the new resource as updated" do
          directory.run_action(:delete)
          expect(new_resource).not_to be_updated
        end
      end

      describe "and one directory does not exist" do
        before do
          FileUtils.rmdir tmp_dir_array.first
        end

        it "deletes all remaining directories" do
          directory.run_action(:delete)
          tmp_dir_array.each do |dir|
            expect(File.exist?(dir)).to be false
          end
        end

        it "sets the new resource as updated" do
          directory.run_action(:delete)
          expect(new_resource).to be_updated
        end
      end

      describe "and neither directory is writable" do
        before do
          allow(Chef::FileAccessControl).to receive(:writable?).and_return(false)
        end

        it "cannot delete it and raises an exception" do
          expect { directory.run_action(:delete) }.to raise_error(RuntimeError)
        end
      end

      describe "and both target directories are files" do
        before do
          tmp_dir_array.each do |d|
            FileUtils.rmdir d
            FileUtils.touch d
          end
        end

        it "cannot delete them and raises an exception" do
          expect { directory.run_action(:delete) }.to raise_error(RuntimeError)
        end
      end

      describe "and one of the target directories is a file" do
        before do
          FileUtils.rmdir tmp_dir_array.first
          FileUtils.touch tmp_dir_array.first
        end

        it "cannot delete it and raises an exception" do
          expect { directory.run_action(:delete) }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
