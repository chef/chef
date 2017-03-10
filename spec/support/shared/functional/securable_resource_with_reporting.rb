
require "functional/resource/base"

ALL_EXPANDED_PERMISSIONS = ["generic read",
                            "generic write",
                            "generic execute",
                            "generic all",
                            "delete",
                            "read permissions",
                            "change permissions",
                            "take ownership",
                            "synchronize",
                            "access system security",
                            "read data / list directory",
                            "write data / add file",
                            "append data / add subdirectory",
                            "read extended attributes",
                            "write extended attributes",
                            "execute / traverse",
                            "delete child",
                            "read attributes",
                            "write attributes"]

shared_examples_for "a securable resource with reporting" do

  include_context "diff disabled"

  let(:current_resource) do
    provider = resource.provider_for_action(resource.action)
    provider.load_current_resource
    provider.current_resource
  end

  # Default mode varies based on implementation. Providers that use a tempfile
  # will default to 0600. Providers that use File.open will default to 0666 -
  # umask
  # let(:default_mode) { (0666 & ~File.umask).to_s(8) }

  describe "reading file security metadata for reporting on unix", :unix_only => true do
    # According to POSIX standard created files get either the
    # effective gid of the process or inherits the gid of the parent
    # directory based on file system. Since it's hard to guess what
    # would happen on each platform we create a dummy file and see
    # what the group name should be.
    before do
      FileUtils.touch(path)
      @expected_gid = File.stat(path).gid
      @expected_group_name = Etc.getgrgid(@expected_gid).name
      FileUtils.rm_rf(path)
    end

    context "when the target file doesn't exist" do
      before do
        resource.action(:create)
      end

      it "has empty values for file metadata in 'current_resource'" do
        expect(current_resource.owner).to be_nil
        expect(current_resource.group).to be_nil
        expect(current_resource.mode).to be_nil
      end

      context "and no security metadata is specified in new_resource" do
        it "sets the metadata values on the new_resource as strings after creating" do
          resource.run_action(:create)
          # TODO: most stable way to specify?
          expect(resource.owner).to eq(Etc.getpwuid(Process.uid).name)
          expect(resource.group).to eq(@expected_group_name)
          expect(resource.mode).to eq("0#{default_mode}")
        end
      end

      context "and owner is specified with a String (username) in new_resource", :requires_root => true do

        # TODO/bug: duplicated from the "securable resource" tests

        if ohai[:platform] == "aix"
          let(:expected_user_name) { "guest" }
        else
          let(:expected_user_name) { "nobody" }
        end

        before do
          resource.owner(expected_user_name)
          resource.run_action(:create)
        end

        it "sets the owner on new_resource to the username (String) of the desired owner" do
          expect(resource.owner).to eq(expected_user_name)
        end

      end

      context "and owner is specified with an Integer (uid) in new_resource", :requires_root => true do

        # TODO: duplicated from "securable resource"
        if ohai[:platform] == "aix"
          let(:expected_user_name) { "guest" }
        else
          let(:expected_user_name) { "nobody" }
        end
        let(:expected_uid) { Etc.getpwnam(expected_user_name).uid }
        let(:desired_gid) { 1337 }
        let(:expected_gid) { 1337 }

        before do
          resource.owner(expected_uid)
          resource.run_action(:create)
        end

        it "sets the owner on new_resource to the uid (Integer) of the desired owner" do
          expect(resource.owner).to eq(expected_uid)
        end
      end

      context "and group is specified with a String (group name)", :requires_root => true do

        let(:expected_group_name) { Etc.getgrent.name }

        before do
          resource.group(expected_group_name)
          resource.run_action(:create)
        end

        it "sets the group on new_resource to the group name (String) of the group" do
          expect(resource.group).to eq(expected_group_name)
        end

      end

      context "and group is specified with an Integer (gid)", :requires_root => true do
        let(:expected_gid) { Etc.getgrent.gid }

        before do
          resource.group(expected_gid)
          resource.run_action(:create)
        end

        it "sets the group on new_resource to the gid (Integer)" do
          expect(resource.group).to eq(expected_gid)
        end

      end

      context "and mode is specified as a String" do
        # Need full permission for owner here or else remote directory gets
        # into trouble trying to manage nested directories
        let(:set_mode) { "0740" }
        let(:expected_mode) { "0740" }

        before do
          resource.mode(set_mode)
          resource.run_action(:create)
        end

        it "sets mode on the new_resource as a String" do
          expect(resource.mode).to eq(expected_mode)
        end
      end

      context "and mode is specified as an Integer" do
        let(:set_mode) { 00740 }

        let(:expected_mode) { "0740" }
        before do
          resource.mode(set_mode)
          resource.run_action(:create)
        end

        it "sets mode on the new resource as a String" do
          expect(resource.mode).to eq(expected_mode)
        end
      end
    end

    context "when the target file exists" do
      before do
        FileUtils.touch(resource.path)
        resource.action(:create)
      end

      context "and no security metadata is specified in new_resource" do
        it "sets the current values on current resource as strings" do
          # TODO: most stable way to specify?
          expect(current_resource.owner).to eq(Etc.getpwuid(Process.uid).name)
          expect(current_resource.group).to eq(@expected_group_name)
          expect(current_resource.mode).to eq("0#{(0666 & ~File.umask).to_s(8)}")
        end
      end

      context "and owner is specified with a String (username) in new_resource" do

        let(:expected_user_name) { Etc.getpwuid(Process.uid).name }

        before do
          resource.owner(expected_user_name)
        end

        it "sets the owner on new_resource to the username (String) of the desired owner" do
          expect(current_resource.owner).to eq(expected_user_name)
        end

      end

      context "and owner is specified with an Integer (uid) in new_resource" do

        let(:expected_uid) { Process.uid }

        before do
          resource.owner(expected_uid)
        end

        it "sets the owner on new_resource to the uid (Integer) of the desired owner" do
          expect(current_resource.owner).to eq(expected_uid)
        end
      end

      context "and group is specified with a String (group name)" do
        before do
          resource.group(@expected_group_name)
        end

        it "sets the group on new_resource to the group name (String) of the group" do
          expect(current_resource.group).to eq(@expected_group_name)
        end

      end

      context "and group is specified with an Integer (gid)" do
        before do
          resource.group(@expected_gid)
        end

        it "sets the group on new_resource to the gid (Integer)" do
          expect(current_resource.group).to eq(@expected_gid)
        end

      end

      context "and mode is specified as a String" do
        let(:default_create_mode) { 0666 & ~File.umask }
        let(:expected_mode) { "0#{default_create_mode.to_s(8)}" }

        before do
          resource.mode(expected_mode)
        end

        it "sets mode on the new_resource as a String" do
          expect(current_resource.mode).to eq(expected_mode)
        end
      end

      context "and mode is specified as an Integer" do
        let(:set_mode) { 0666 & ~File.umask }
        let(:expected_mode) { "0#{set_mode.to_s(8)}" }

        before do
          resource.mode(set_mode)
        end

        it "sets mode on the new resource as a String" do
          expect(current_resource.mode).to eq(expected_mode)
        end
      end
    end
  end

  describe "reading file security metadata for reporting on windows", :windows_only do

    context "when the target file doesn't exist" do

      # Windows reporting data should look like this (+/- ish):
      # { "owner" => "bob", "checksum" => "ffff", "access control" => { "bob" => { "permissions" => ["perm1", "perm2", ...], "flags" => [] }}}

      before do
        resource.action(:create)
      end

      it "has empty values for file metadata in 'current_resource'" do
        skip "windows reporting not yet fully supported"
        expect(current_resource.owner).to be_nil
        expect(current_resource.expanded_rights).to be_nil
      end

      context "and no security metadata is specified in new_resource" do
        before do
          skip "windows reporting not yet fully supported"
        end

        it "sets the metadata values on the new_resource as strings after creating" do
          resource.run_action(:create)
          # TODO: most stable way to specify?
          expect(resource.owner).to eq(etc.getpwuid(process.uid).name)
          expect(resource.state[:expanded_rights]).to eq({ "CURRENTUSER" => { "permissions" => ALL_EXPANDED_PERMISSIONS, "flags" => [] } })
          expect(resource.state[:expanded_deny_rights]).to eq({})
          expect(resource.state[:inherits]).to be_truthy
        end
      end

      context "and owner is specified with a string (username) in new_resource" do

        # TODO/bug: duplicated from the "securable resource" tests
        let(:expected_user_name) { "Guest" }

        before do
          resource.owner(expected_user_name)
          resource.run_action(:create)
        end

        it "sets the owner on new_resource to the username (string) of the desired owner" do
          expect(resource.owner).to eq(expected_user_name)
        end

      end

      context "and owner is specified with a fully qualified domain user" do

        # TODO: duplicated from "securable resource"
        let(:expected_user_name) { 'domain\user' }

        before do
          skip "windows reporting not yet fully supported"
          resource.owner(expected_user_name)
          resource.run_action(:create)
        end

        it "sets the owner on new_resource to the fully qualified name of the desired owner" do
          expect(resource.owner).to eq(expected_user_name)
        end
      end

    end

    context "when the target file exists" do
      before do
        skip "windows reporting not yet fully supported"
        FileUtils.touch(resource.path)
        resource.action(:create)
      end

      context "and no security metadata is specified in new_resource" do
        it "sets the current values on current resource as strings" do
          # TODO: most stable way to specify?
          expect(current_resource.owner).to eq(etc.getpwuid(process.uid).name)
          expect(current_resource.expanded_rights).to eq({ "CURRENTUSER" => ALL_EXPANDED_PERMISSIONS })
        end
      end

      context "and owner is specified with a string (username) in new_resource" do

        let(:expected_user_name) { etc.getpwuid(process.uid).name }

        before do
          resource.owner(expected_user_name)
        end

        it "sets the owner on current_resource to the username (string) of the desired owner" do
          expect(current_resource.owner).to eq(expected_user_name)
        end

      end

      context "and owner is specified as a fully qualified 'domain\\user' in new_resource" do

        let(:expected_user_name) { 'domain\user' }

        before do
          resource.owner(expected_user_name)
        end

        it "sets the owner on current_resource to the fully qualified name of the desired owner" do
          expect(current_resource.owner).to eq(expected_uid)
        end
      end

      context "and access rights are specified on the new_resource" do
        # TODO: before do blah

        it "sets the expanded_rights on the current resource" do
          skip
        end
      end

      context "and no access rights are specified on the current resource" do
        # TODO: before do blah

        it "sets the expanded rights on the current resource" do
          skip
        end
      end

    end
  end
end
