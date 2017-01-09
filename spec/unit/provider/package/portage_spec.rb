#
# Author:: Caleb Tennis (<caleb.tennis@gmail.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::Provider::Package::Portage, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("dev-util/git")
    @new_resource_without_category = Chef::Resource::Package.new("git")
    @current_resource = Chef::Resource::Package.new("dev-util/git")

    @provider = Chef::Provider::Package::Portage.new(@new_resource, @run_context)
    allow(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
  end

  describe "when determining the current state of the package" do

    it "should create a current resource with the name of new_resource" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/dev-util/git-*").and_return(["/var/db/pkg/dev-util/git-1.0.0"])
      expect(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resource package name to the new resource package name" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/dev-util/git-*").and_return(["/var/db/pkg/dev-util/git-1.0.0"])
      expect(@current_resource).to receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should return a current resource with the correct version if the package is found" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/dev-util/git-*").and_return(["/var/db/pkg/dev-util/git-foobar-0.9", "/var/db/pkg/dev-util/git-1.0.0"])
      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq("1.0.0")
    end

    it "should return a current resource with the correct version if the package is found with revision" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/dev-util/git-*").and_return(["/var/db/pkg/dev-util/git-1.0.0-r1"])
      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq("1.0.0-r1")
    end

    it "should return a current resource with the correct version if the package is found with version with character" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/dev-util/git-*").and_return(["/var/db/pkg/dev-util/git-1.0.0d"])
      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq("1.0.0d")
    end

    it "should return a current resource with a nil version if the package is not found" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/dev-util/git-*").and_return(["/var/db/pkg/dev-util/notgit-1.0.0"])
      @provider.load_current_resource
      expect(@provider.current_resource.version).to be_nil
    end

    it "should return a package name match from /var/db/pkg/* if a category isn't specified and a match is found" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/*/git-*").and_return(["/var/db/pkg/dev-util/git-foobar-0.9", "/var/db/pkg/dev-util/git-1.0.0"])
      @provider = Chef::Provider::Package::Portage.new(@new_resource_without_category, @run_context)
      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq("1.0.0")
    end

    it "should return a current resource with a nil version if a category isn't specified and a name match from /var/db/pkg/* is not found" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/*/git-*").and_return(["/var/db/pkg/dev-util/notgit-1.0.0"])
      @provider = Chef::Provider::Package::Portage.new(@new_resource_without_category, @run_context)
      @provider.load_current_resource
      expect(@provider.current_resource.version).to be_nil
    end

    it "should throw an exception if a category isn't specified and multiple packages are found" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/*/git-*").and_return(["/var/db/pkg/dev-util/git-1.0.0", "/var/db/pkg/funny-words/git-1.0.0"])
      @provider = Chef::Provider::Package::Portage.new(@new_resource_without_category, @run_context)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
    end

    it "should return a current resource with a nil version if a category is specified and multiple packages are found" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/dev-util/git-*").and_return(["/var/db/pkg/dev-util/git-1.0.0", "/var/db/pkg/funny-words/git-1.0.0"])
      @provider = Chef::Provider::Package::Portage.new(@new_resource, @run_context)
      @provider.load_current_resource
      expect(@provider.current_resource.version).to be_nil
    end

    it "should return a current resource with a nil version if a category is not specified and multiple packages from the same category are found" do
      allow(::Dir).to receive(:[]).with("/var/db/pkg/*/git-*").and_return(["/var/db/pkg/dev-util/git-1.0.0", "/var/db/pkg/dev-util/git-1.0.1"])
      @provider = Chef::Provider::Package::Portage.new(@new_resource_without_category, @run_context)
      @provider.load_current_resource
      expect(@provider.current_resource.version).to be_nil
    end
  end

  describe "once the state of the package is known" do

    describe Chef::Provider::Package::Portage, "candidate_version" do
      it "should return the candidate_version variable if already set" do
        @provider.candidate_version = "1.0.0"
        expect(@provider).not_to receive(:shell_out)
        @provider.candidate_version
      end

      it "should throw an exception if the exitstatus is not 0" do
        status = double(:stdout => "", :exitstatus => 1)
        allow(@provider).to receive(:shell_out).and_return(status)
        expect { @provider.candidate_version }.to raise_error(Chef::Exceptions::Package)
      end

      it "should find the candidate_version if a category is specifed and there are no duplicates" do
        output = <<EOF
Searching...
[ Results for search key : git ]
[ Applications found : 14 ]

*  app-misc/digitemp [ Masked ]
      Latest version available: 3.5.0
      Latest version installed: [ Not Installed ]
      Size of files: 261 kB
      Homepage:      http://www.digitemp.com/ http://www.ibutton.com/
      Description:   Temperature logging and reporting using Dallas Semiconductor's iButtons and 1-Wire protocol
      License:       GPL-2

*  dev-util/git
      Latest version available: 1.6.0.6
      Latest version installed: ignore
      Size of files: 2,725 kB
      Homepage:      http://git.or.cz/
      Description:   GIT - the stupid content tracker, the revision control system heavily used by the Linux kernel team
      License:       GPL-2

*  dev-util/gitosis [ Masked ]
      Latest version available: 0.2_p20080825
      Latest version installed: [ Not Installed ]
      Size of files: 31 kB
      Homepage:      http://eagain.net/gitweb/?p=gitosis.git;a=summary
      Description:   gitosis -- software for hosting git repositories
      License:       GPL-2
EOF

        status = double(:stdout => output, :exitstatus => 0)
        expect(@provider).to receive(:shell_out).and_return(status)
        expect(@provider.candidate_version).to eq("1.6.0.6")
      end

      it "should find the candidate_version if a category is not specifed and there are no duplicates" do
        output = <<EOF
Searching...
[ Results for search key : git ]
[ Applications found : 14 ]

*  app-misc/digitemp [ Masked ]
      Latest version available: 3.5.0
      Latest version installed: [ Not Installed ]
      Size of files: 261 kB
      Homepage:      http://www.digitemp.com/ http://www.ibutton.com/
      Description:   Temperature logging and reporting using Dallas Semiconductor's iButtons and 1-Wire protocol
      License:       GPL-2

*  dev-util/git
      Latest version available: 1.6.0.6
      Latest version installed: ignore
      Size of files: 2,725 kB
      Homepage:      http://git.or.cz/
      Description:   GIT - the stupid content tracker, the revision control system heavily used by the Linux kernel team
      License:       GPL-2

*  dev-util/gitosis [ Masked ]
      Latest version available: 0.2_p20080825
      Latest version installed: [ Not Installed ]
      Size of files: 31 kB
      Homepage:      http://eagain.net/gitweb/?p=gitosis.git;a=summary
      Description:   gitosis -- software for hosting git repositories
      License:       GPL-2
EOF

        status = double(:stdout => output, :exitstatus => 0)
        @provider = Chef::Provider::Package::Portage.new(@new_resource_without_category, @run_context)
        expect(@provider).to receive(:shell_out).and_return(status)
        expect(@provider.candidate_version).to eq("1.6.0.6")
      end

      it "should throw an exception if a category is not specified and there are duplicates" do
        output = <<EOF
Searching...
[ Results for search key : git ]
[ Applications found : 14 ]

*  app-misc/digitemp [ Masked ]
      Latest version available: 3.5.0
      Latest version installed: [ Not Installed ]
      Size of files: 261 kB
      Homepage:      http://www.digitemp.com/ http://www.ibutton.com/
      Description:   Temperature logging and reporting using Dallas Semiconductor's iButtons and 1-Wire protocol
      License:       GPL-2

*  app-misc/git
      Latest version available: 4.3.20
      Latest version installed: [ Not Installed ]
      Size of files: 416 kB
      Homepage:      http://www.gnu.org/software/git/
      Description:   GNU Interactive Tools - increase speed and efficiency of most daily task
      License:       GPL-2

*  dev-util/git
      Latest version available: 1.6.0.6
      Latest version installed: ignore
      Size of files: 2,725 kB
      Homepage:      http://git.or.cz/
      Description:   GIT - the stupid content tracker, the revision control system heavily used by the Linux kernel team
      License:       GPL-2

*  dev-util/gitosis [ Masked ]
      Latest version available: 0.2_p20080825
      Latest version installed: [ Not Installed ]
      Size of files: 31 kB
      Homepage:      http://eagain.net/gitweb/?p=gitosis.git;a=summary
      Description:   gitosis -- software for hosting git repositories
      License:       GPL-2
EOF

        status = double(:stdout => output, :exitstatus => 0)
        @provider = Chef::Provider::Package::Portage.new(@new_resource_without_category, @run_context)
        expect(@provider).to receive(:shell_out).and_return(status)
        expect { @provider.candidate_version }.to raise_error(Chef::Exceptions::Package)
      end

      it "should find the candidate_version if a category is specifed and there are category duplicates" do
        output = <<EOF
Searching...
[ Results for search key : git ]
[ Applications found : 14 ]

*  app-misc/digitemp [ Masked ]
      Latest version available: 3.5.0
      Latest version installed: [ Not Installed ]
      Size of files: 261 kB
      Homepage:      http://www.digitemp.com/ http://www.ibutton.com/
      Description:   Temperature logging and reporting using Dallas Semiconductor's iButtons and 1-Wire protocol
      License:       GPL-2

*  app-misc/git
      Latest version available: 4.3.20
      Latest version installed: [ Not Installed ]
      Size of files: 416 kB
      Homepage:      http://www.gnu.org/software/git/
      Description:   GNU Interactive Tools - increase speed and efficiency of most daily task
      License:       GPL-2

*  dev-util/git
      Latest version available: 1.6.0.6
      Latest version installed: ignore
      Size of files: 2,725 kB
      Homepage:      http://git.or.cz/
      Description:   GIT - the stupid content tracker, the revision control system heavily used by the Linux kernel team
      License:       GPL-2

*  dev-util/gitosis [ Masked ]
      Latest version available: 0.2_p20080825
      Latest version installed: [ Not Installed ]
      Size of files: 31 kB
      Homepage:      http://eagain.net/gitweb/?p=gitosis.git;a=summary
      Description:   gitosis -- software for hosting git repositories
      License:       GPL-2
EOF

        status = double(:stdout => output, :exitstatus => 0)
        @provider = Chef::Provider::Package::Portage.new(@new_resource, @run_context)
        expect(@provider).to receive(:shell_out).and_return(status)
        expect(@provider.candidate_version).to eq("1.6.0.6")
      end
    end

    describe Chef::Provider::Package::Portage, "install_package" do
      it "should install a normally versioned package using portage" do
        expect(@provider).to receive(:shell_out!).with("emerge", "-g", "--color", "n", "--nospinner", "--quiet", "=dev-util/git-1.0.0")
        @provider.install_package("dev-util/git", "1.0.0")
      end

      it "should install a tilde versioned package using portage" do
        expect(@provider).to receive(:shell_out!).with("emerge", "-g", "--color", "n", "--nospinner", "--quiet", "~dev-util/git-1.0.0")
        @provider.install_package("dev-util/git", "~1.0.0")
      end

      it "should add options to the emerge command when specified" do
        expect(@provider).to receive(:shell_out!).with("emerge", "-g", "--color", "n", "--nospinner", "--quiet", "--oneshot", "=dev-util/git-1.0.0")
        @new_resource.options "--oneshot"
        @provider.install_package("dev-util/git", "1.0.0")
      end
    end

    describe Chef::Provider::Package::Portage, "remove_package" do
      it "should un-emerge the package with no version specified" do
        expect(@provider).to receive(:shell_out!).with("emerge", "--unmerge", "--color", "n", "--nospinner", "--quiet", "dev-util/git")
        @provider.remove_package("dev-util/git", nil)
      end

      it "should un-emerge the package with a version specified" do
        expect(@provider).to receive(:shell_out!).with("emerge", "--unmerge", "--color", "n", "--nospinner", "--quiet", "=dev-util/git-1.0.0")
        @provider.remove_package("dev-util/git", "1.0.0")
      end
    end
  end
end
