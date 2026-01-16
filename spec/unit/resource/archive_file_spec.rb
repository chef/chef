#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

begin
  require "ffi-libarchive"
rescue LoadError
  module Archive
    class Reader
      def close; end
      def each_entry; end
      def extract(entry, flags = 0, destination: nil); end
    end
  end
end

describe Chef::Resource::ArchiveFile, :not_supported_on_aix, :not_supported_on_windows do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:destination) { Dir.mktmpdir }
  let(:path) { File.expand_path("/tmp/foo.zip") }
  let(:resource) do
    r = Chef::Resource::ArchiveFile.new(path, run_context)
    r.destination = destination
    r
  end
  let(:provider) { resource.provider_for_action(:extract) }
  let(:entry_time) { Time.new(2021, 5, 25, 2, 2, 0, "-05:00") }
  let(:older_time) { entry_time - 100 }
  let(:newer_time) { entry_time + 100 }

  let(:archive_reader) { instance_double("Archive::Reader", close: nil) }
  let(:archive_entry_1) { instance_double("Archive::Entry", pathname: "folder-1/", mtime: entry_time) }
  let(:archive_entry_2) { instance_double("Archive::Entry", pathname: "folder-1/file-1.txt", mtime: entry_time) }
  let(:archive_entry_3) { instance_double("Archive::Entry", pathname: "folder-1/folder-2/", mtime: entry_time) }
  let(:archive_entry_4) { instance_double("Archive::Entry", pathname: "folder-1/folder-2/file-2.txt", mtime: entry_time) }

  let(:archive_reader_with_strip_components_1) { instance_double("Archive::Reader", close: nil) }
  let(:archive_entry_2_s1) { instance_double("Archive::Entry", pathname: "file-1.txt", mtime: entry_time) }
  let(:archive_entry_3_s1) { instance_double("Archive::Entry", pathname: "folder-2/", mtime: entry_time) }
  let(:archive_entry_4_s1) { instance_double("Archive::Entry", pathname: "folder-2/file-2.txt", mtime: entry_time) }

  let(:archive_reader_with_strip_components_2) { instance_double("Archive::Reader", close: nil) }
  let(:archive_entry_4_s2) { instance_double("Archive::Entry", pathname: "file-2.txt", mtime: entry_time) }

  before do
    allow(resource).to receive(:provider_for_action).with(:extract).and_return(provider)
  end

  it "has a resource name of :archive_file" do
    expect(resource.resource_name).to eql(:archive_file)
  end

  it "has a name property of path" do
    r = Chef::Resource::ArchiveFile.new("my-name", run_context)
    expect(r.path).to match("my-name")
  end

  it "sets the default action as :extract" do
    expect(resource.action).to eql([:extract])
  end

  it "supports :extract action" do
    expect { resource.action :extract }.not_to raise_error
  end

  it "mode property defaults to '755'" do
    expect(resource.mode).to eql("755")
  end

  it "strip_components property defaults to 0" do
    expect(resource.strip_components).to eql(0)
  end

  describe "#action_extract" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:exist?).with(destination).and_return(true)

      allow(Archive::Reader).to receive(:open_filename).with(path, nil, strip_components: 0).and_yield(archive_reader)
      allow(archive_reader).to receive(:each_entry)
        .and_yield(archive_entry_1)
        .and_yield(archive_entry_2)
        .and_yield(archive_entry_3)
        .and_yield(archive_entry_4)
      allow(archive_reader).to receive(:extract).with(archive_entry_1, any_args)
      allow(archive_reader).to receive(:extract).with(archive_entry_2, any_args)
      allow(archive_reader).to receive(:extract).with(archive_entry_3, any_args)
      allow(archive_reader).to receive(:extract).with(archive_entry_4, any_args)

      allow(Archive::Reader).to receive(:open_filename).with(path, nil, strip_components: 1).and_yield(archive_reader_with_strip_components_1)
      allow(archive_reader_with_strip_components_1).to receive(:each_entry)
        .and_yield(archive_entry_2_s1)
        .and_yield(archive_entry_3_s1)
        .and_yield(archive_entry_4_s1)
      allow(archive_reader_with_strip_components_1).to receive(:extract).with(archive_entry_2_s1, any_args)
      allow(archive_reader_with_strip_components_1).to receive(:extract).with(archive_entry_3_s1, any_args)
      allow(archive_reader_with_strip_components_1).to receive(:extract).with(archive_entry_4_s1, any_args)

      allow(Archive::Reader).to receive(:open_filename).with(path, nil, strip_components: 2).and_yield(archive_reader_with_strip_components_2)
      allow(archive_reader_with_strip_components_2).to receive(:each_entry)
        .and_yield(archive_entry_4_s2)
      allow(archive_reader_with_strip_components_2).to receive(:extract).with(archive_entry_4_s2, any_args)

      allow(File).to receive(:exist?).with("#{destination}/folder-1").and_return(true)
      allow(File).to receive(:exist?).with("#{destination}/folder-1/file-1.txt").and_return(true)
      allow(File).to receive(:exist?).with("#{destination}/folder-1/folder-2").and_return(true)
      allow(File).to receive(:exist?).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(true)

      allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(entry_time)
      allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(entry_time)
      allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(entry_time)
      allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(entry_time)

      resource.overwrite(true) # Force it to converge
    end

    context "when destination directory does not exist" do
      before do
        allow(File).to receive(:exist?).with(destination).and_return(false)
      end

      it "creates destination directory" do
        expect(FileUtils).to receive(:mkdir_p).with(destination, { mode: 493 })
        resource.run_action(:extract)
      end
    end

    context "when destination directory exists" do
      before do
        allow(File).to receive(:exist?).with(destination).and_return(true)
      end

      it "does not create destination directory" do
        expect(FileUtils).not_to receive(:mkdir_p)
        resource.run_action(:extract)
      end

      context "when overwrite is set to false" do
        before do
          resource.overwrite(false)
        end

        context "when files on disk have identical modified times than what is in the archive" do
          before do
            allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(entry_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(entry_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(entry_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(entry_time)
          end

          it "does not extract archive" do
            expect(provider).not_to receive(:extract)
            resource.run_action(:extract)
          end
        end

        context "when files on disk have newer modified times than what is in the archive" do
          before do
            allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(newer_time)
          end

          it "does not extract archive" do
            expect(provider).not_to receive(:extract)
            resource.run_action(:extract)
          end
        end

        context "when files on disk have older modified times than what is in the archive" do
          before do
            allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(older_time)
          end

          it "does not extract archive" do
            expect(provider).not_to receive(:extract)
            resource.run_action(:extract)
          end
        end
      end

      context "when overwrite is set to true" do
        before do
          resource.overwrite(true)
        end

        context "when files on disk have identical modified times than what is in the archive" do
          before do
            allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(entry_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(entry_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(entry_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(entry_time)
          end

          it "extracts archive" do
            expect(provider).to receive(:extract)
            resource.run_action(:extract)
          end
        end

        context "when files on disk have newer modified times than what is in the archive" do
          before do
            allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(newer_time)
          end

          it "extracts archive" do
            expect(provider).to receive(:extract)
            resource.run_action(:extract)
          end
        end

        context "when files on disk have older modified times than what is in the archive" do
          before do
            allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(older_time)
          end

          it "extracts archive" do
            expect(provider).to receive(:extract)
            resource.run_action(:extract)
          end
        end
      end

      context "when overwrite is set to :auto" do
        before do
          resource.overwrite(:auto)
        end

        context "when strip_components is set to 0" do
          before do
            resource.strip_components(0)
          end

          context "when files on disk have identical modified times than what is in the archive" do
            before do
              allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(entry_time)
              allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(entry_time)
              allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(entry_time)
              allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(entry_time)
            end

            context "when there is at least one missing files on disk" do
              before do
                expect(File).to receive(:exist?).with("#{destination}/folder-1").and_return(false)
                expect(File).to receive(:exist?).with("#{destination}/folder-1/file-1.txt").and_return(true)
                expect(File).to receive(:exist?).with("#{destination}/folder-1/folder-2").and_return(true)
                expect(File).to receive(:exist?).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(true)
              end

              it "extracts archive" do
                expect(provider).to receive(:extract)
                resource.run_action(:extract)
              end
            end

            context "when there are no missing files on disk" do
              before do
                expect(File).to receive(:exist?).with("#{destination}/folder-1").and_return(true)
                expect(File).to receive(:exist?).with("#{destination}/folder-1/file-1.txt").and_return(true)
                expect(File).to receive(:exist?).with("#{destination}/folder-1/folder-2").and_return(true)
                expect(File).to receive(:exist?).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(true)
              end

              it "does not extract archive" do
                expect(provider).not_to receive(:extract)
                resource.run_action(:extract)
              end
            end
          end
        end

        context "when strip_components is set to 1" do
          before do
            resource.strip_components(1)
          end

          context "when files on disk have identical modified times than what is in the archive" do
            before do
              allow(File).to receive(:mtime).with("#{destination}/file-1.txt").and_return(entry_time)
              allow(File).to receive(:mtime).with("#{destination}/folder-2").and_return(entry_time)
              allow(File).to receive(:mtime).with("#{destination}/folder-2/file-2.txt").and_return(entry_time)
            end

            context "when there is at least one missing files on disk" do
              before do
                expect(File).not_to receive(:exist?).with("#{destination}/folder-1")
                expect(File).not_to receive(:exist?).with("#{destination}/folder-1/file-1.txt")
                expect(File).not_to receive(:exist?).with("#{destination}/folder-1/folder-2")
                expect(File).not_to receive(:exist?).with("#{destination}/folder-1/folder-2/file-2.txt")
                expect(File).to receive(:exist?).with("#{destination}/file-1.txt").and_return(false)
                expect(File).to receive(:exist?).with("#{destination}/folder-2").and_return(true)
                expect(File).to receive(:exist?).with("#{destination}/folder-2/file-2.txt").and_return(true)
              end

              it "extracts archive" do
                expect(provider).to receive(:extract)
                resource.run_action(:extract)
              end
            end

            context "when there are no missing files on disk" do
              before do
                expect(File).not_to receive(:exist?).with("#{destination}/folder-1")
                expect(File).not_to receive(:exist?).with("#{destination}/folder-1/file-1.txt")
                expect(File).not_to receive(:exist?).with("#{destination}/folder-1/folder-2")
                expect(File).not_to receive(:exist?).with("#{destination}/folder-1/folder-2/file-2.txt")
                expect(File).to receive(:exist?).with("#{destination}/file-1.txt").and_return(true)
                expect(File).to receive(:exist?).with("#{destination}/folder-2").and_return(true)
                expect(File).to receive(:exist?).with("#{destination}/folder-2/file-2.txt").and_return(true)
              end

              it "does not extract archive" do
                expect(provider).not_to receive(:extract)
                resource.run_action(:extract)
              end
            end
          end
        end

        context "when files on disk have newer modified times than what is in the archive" do
          before do
            allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(newer_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(newer_time)
          end

          it "extracts archive" do
            expect(provider).to receive(:extract)
            resource.run_action(:extract)
          end
        end

        context "when files on disk have older modified times than what is in the archive" do
          before do
            allow(File).to receive(:mtime).with("#{destination}/folder-1").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/file-1.txt").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2").and_return(older_time)
            allow(File).to receive(:mtime).with("#{destination}/folder-1/folder-2/file-2.txt").and_return(older_time)
          end

          it "extracts archive" do
            expect(provider).to receive(:extract)
            resource.run_action(:extract)
          end
        end
      end
    end

    context "when strip_components is set to 0" do
      before do
        resource.strip_components(0)
      end

      it "does not strip any paths" do
        expect(archive_reader).to receive(:extract).with(archive_entry_1, 4)
        expect(archive_reader).to receive(:extract).with(archive_entry_2, 4)
        expect(archive_reader).to receive(:extract).with(archive_entry_3, 4)
        expect(archive_reader).to receive(:extract).with(archive_entry_4, 4)
        resource.run_action(:extract)
      end
    end

    context "when strip_components is set to 1" do
      before do
        resource.strip_components(1)
      end

      it "strips leading number of paths specified in strip_components" do
        expect(archive_reader_with_strip_components_1).to receive(:extract).with(archive_entry_2_s1, 4)
        expect(archive_reader_with_strip_components_1).to receive(:extract).with(archive_entry_3_s1, 4)
        expect(archive_reader_with_strip_components_1).to receive(:extract).with(archive_entry_4_s1, 4)
        resource.run_action(:extract)
      end
    end

    context "when strip_components is set to 2" do
      before do
        resource.strip_components(2)
      end

      it "strips leading number of paths specified in strip_components" do
        expect(archive_reader_with_strip_components_2).to receive(:extract).with(archive_entry_4_s2, 4)
        resource.run_action(:extract)
      end
    end

    context "when owner property is set" do
      before { resource.owner "root" }

      it "chowns all archive file/directory paths" do
        expect(FileUtils).to receive(:chown).with("root", nil, "#{destination}/folder-1/")
        expect(FileUtils).to receive(:chown).with("root", nil, "#{destination}/folder-1/file-1.txt")
        expect(FileUtils).to receive(:chown).with("root", nil, "#{destination}/folder-1/folder-2/")
        expect(FileUtils).to receive(:chown).with("root", nil, "#{destination}/folder-1/folder-2/file-2.txt")
        resource.run_action(:extract)
      end
    end

    context "when group property is set" do
      before { resource.group "root" }

      it "chowns all archive file/directory paths" do
        expect(FileUtils).to receive(:chown).with(nil, "root", "#{destination}/folder-1/")
        expect(FileUtils).to receive(:chown).with(nil, "root", "#{destination}/folder-1/file-1.txt")
        expect(FileUtils).to receive(:chown).with(nil, "root", "#{destination}/folder-1/folder-2/")
        expect(FileUtils).to receive(:chown).with(nil, "root", "#{destination}/folder-1/folder-2/file-2.txt")
        resource.run_action(:extract)
      end
    end

    context "when owner and group properties are set" do
      before do
        resource.owner "root"
        resource.group "root"
      end

      it "chowns all archive file/directory paths" do
        expect(FileUtils).to receive(:chown).with("root", "root", "#{destination}/folder-1/")
        expect(FileUtils).to receive(:chown).with("root", "root", "#{destination}/folder-1/file-1.txt")
        expect(FileUtils).to receive(:chown).with("root", "root", "#{destination}/folder-1/folder-2/")
        expect(FileUtils).to receive(:chown).with("root", "root", "#{destination}/folder-1/folder-2/file-2.txt")
        resource.run_action(:extract)
      end
    end
  end

  it "mode property throws a deprecation warning if Integers are passed" do
    expect(Chef::Log).to receive(:deprecation)
    resource.mode 755
    provider.define_resource_requirements
  end

  it "options property defaults to [:time]" do
    expect(resource.options).to eql([:time])
  end
end
