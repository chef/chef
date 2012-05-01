#
# Author:: Caleb Tennis (<caleb.tennis@gmail.com>)
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

describe Chef::Provider::Package::Portage do
  include SpecHelpers::Providers::Package

  let(:package_name) { 'dev-util/git' }
  let(:package_name_without_category) { 'git' }
  let(:new_resource_without_category) { Chef::Resource::Package.new("git") }

  describe '#load_current_resource' do
    subject { given; provider.load_current_resource }

    let(:given) { assume_installed_version }
    let(:installed_version) { rand(100000).to_s }

    it 'should return the current resource' do
      subject
      should eql(provider.current_resource)
    end

    it "should create a current resource with the name of new_resource" do
      subject.name.should eql(new_resource.name)
    end

    it "should set the current resource package name to the new resource package name" do
      subject.package_name.should eql(new_resource.package_name)
    end

    it 'should set the current version' do
      subject.version.should eql(installed_version)
    end
  end

  describe "#candidate_version" do
    subject { given; provider.candidate_version }
    let(:given) { should_shell_out! }

    let(:output_from_emerge_without_duplicates) { <<EOF }
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

      let(:output_from_emerge_with_duplicates) { <<EOF }
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

    it "should return the candidate_version variable if already set" do
      provider.candidate_version = "1.0.0"
      provider.should_not_receive(:shell_out!)
      provider.candidate_version
    end

    context 'with exitstatus is 1' do
      let(:exitstatus) { 1 }

      it "should throw an exception if the exitstatus is not 0" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end

    context 'without duplicates' do
      let(:stdout) { output_from_emerge_without_duplicates }

      it "should find the candidate version " do
        should eql("1.6.0.6")
      end

      context 'without a specified category' do
        let(:new_resource) { new_resource_without_category }

        it "should find the candidate_version if a category is not specifed and there are no duplicates" do
          should eql("1.6.0.6")
        end
      end
    end

    context 'with duplicates' do
      let(:stdout) { output_from_emerge_with_duplicates }

      it "should throw an exception if a category is not specified and there are duplicates" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end

  end

  describe "#install_package" do
    it "should install a normally versioned package using portage" do
      provider.should_receive(:shell_out_with_systems_locale!).with("emerge -g --color n --nospinner --quiet =dev-util/git-1.0.0")
      provider.install_package("dev-util/git", "1.0.0")
    end

    it "should install a tilde versioned package using portage" do
      provider.should_receive(:shell_out_with_systems_locale!).with("emerge -g --color n --nospinner --quiet ~dev-util/git-1.0.0")
      provider.install_package("dev-util/git", "~1.0.0")
    end

    it "should add options to the emerge command when specified" do
      provider.should_receive(:shell_out_with_systems_locale!).with("emerge -g --color n --nospinner --quiet --oneshot =dev-util/git-1.0.0")
      new_resource.stub!(:options).and_return("--oneshot")

      provider.install_package("dev-util/git", "1.0.0")
    end
  end

  describe "#remove_package" do
    it "should un-emerge the package with no version specified" do
      provider.should_receive(:shell_out_with_systems_locale!).with("emerge --unmerge --color n --nospinner --quiet dev-util/git")
      provider.remove_package("dev-util/git", nil)
    end

    it "should un-emerge the package with a version specified" do
      provider.should_receive(:shell_out_with_systems_locale!).with("emerge --unmerge --color n --nospinner --quiet =dev-util/git-1.0.0")
      provider.remove_package("dev-util/git", "1.0.0")
    end
  end

  describe '#installed_version' do
    subject { given; provider.installed_version }
    let(:given) { should_search_portage_db }

    let(:should_search_portage_db) { ::Dir.should_receive(:[]).with(package_glob).and_return(ebuild_candidates) }
    let(:package_glob) { "/var/db/pkg/dev-util/git-*" }

    context 'with installed package' do
      let(:ebuild_candidates) { ["/var/db/pkg/dev-util/git-foobar-0.9", "/var/db/pkg/dev-util/git-1.0.0"] }

      it "should return version" do
        should eql('1.0.0')
      end
    end

    context 'with installed, revised package' do
      let(:ebuild_candidates) { ["/var/db/pkg/dev-util/git-1.0.0-r1"] }

      it "should return a current resource with the correct version if the package is found with revision" do
        should eql("1.0.0-r1")
      end
    end

    context 'without installed package' do
      let(:ebuild_candidates) { ["/var/db/pkg/dev-util/notgit-1.0.0"] }
      it { should be_nil }
    end

    context 'with multiple candidates spanning categories' do
      let(:ebuild_candidates) { ["/var/db/pkg/dev-util/git-1.0.0", "/var/db/pkg/funny-words/git-1.0.0"] }
      it { should be_nil }
    end

    context 'with unspecified category' do
      let(:package_name) { 'git' }
      let(:package_glob) { "/var/db/pkg/*/git-*" }

      context 'with installed version' do
        let(:ebuild_candidates) { ["/var/db/pkg/dev-util/git-foobar-0.9", "/var/db/pkg/dev-util/git-1.0.0"] }

        it 'should return version' do
          should eql('1.0.0')
        end
      end

      context 'without correct package' do
        let(:ebuild_candidates) { ["/var/db/pkg/dev-util/notgit-1.0.0"] }
        it { should be_nil }
      end

      context 'with multiple candidates spanning categories' do
        let(:ebuild_candidates) { ["/var/db/pkg/dev-util/git-1.0.0", "/var/db/pkg/funny-words/git-1.0.0"] }

        it "should throw an exception if a category isn't specified and multiple packages are found" do
          lambda { subject }.should raise_error(Chef::Exceptions::Package)
        end
      end

      context 'with multiple candidates within a single category' do
        let(:ebuild_candidates) { ["/var/db/pkg/dev-util/git-1.0.0", "/var/db/pkg/dev-util/git-1.0.1"] }
        it { should be_nil }
      end
    end

  end
end
