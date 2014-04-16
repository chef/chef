#
# Author:: Vasiliy Tolstov <v.tolstov@selfip.ru>
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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
require 'ostruct'

# based on the ips specs

describe Chef::Provider::Package::Paludis do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("dev-scm/git")
    @current_resource = Chef::Resource::Package.new("dev-scm/git")
    Chef::Resource::Package.stub(:new).and_return(@current_resource)
    @provider = Chef::Provider::Package::Paludis.new(@new_resource, @run_context)

    @stdin = StringIO.new
    @stderr = StringIO.new
    @stdout =<<-PKG_STATUS
* dev-scm/git
    ::arbor                   1.8.4.5(~) 1.8.5.5(~) 1.9.2(~)* {:0}
    dev-scm/git-1.9.2:0::arbor (system)
    Homepage                  http://git-scm.com/
    Summary                   A distributed VCS focused on speed, effectivity and real-world usability on large projects
    Description               Git is a fast, scalable, distributed revision control system with an unusually rich command set that provides both high-level operations and full access to internals
    Options
        OPTIONS
            -baselayout       Install baselayout-1 init files
            bash-completion   Enable bash-completion support
            curl              Adds support for client-side URL transfer library
            -doc              Adds extra documentation (API, Javadoc, etc)
            emacs             Install various Emacs libraries: git.el, git-blame.el and vc-git.el
            -python           Install helper scripts for git remote helpers, a compatibility layer with other SCMs
            systemd           Add support for the systemd init daemon (usually by installing units (configuration files)).
            -tk               Adds support for Tk GUI toolkit
            -webdav           Adds support for pushing using http:// and https:// transports
            -xinetd           Add support for the xinetd super-server
            -zsh-completion   Install completion files for the Z shell
        git_remote_helpers
            -bzr              Install the Bazaar remote helper (e. g. git clone bzr::lp:gnuhello)
            -mercurial        Install the Mecurial remote helper (e. g. git clone hg::http://selenic.com/repo/hello)
        Build Options
            symbols=split     How to handle debug symbols in installed files
                              Permitted values:
                                  compress:  Split and compress debug symbols
                                  preserve:  Preserve debug symbols
                                  split:     Split debug symbols
                                  strip:     Strip debug symbols
            jobs=3            How many jobs the package's build system should use, where supported
                              Should be an integer >= 1
            -dwarf_compress   Compress DWARF2+ debug information
            -recommended_tests Run tests considered by the package to be recommended
            -trace            Trace actions executed by the package (very noisy, for debugging broken builds only)
            work=tidyup       Whether to preserve or remove working directories
                              Permitted values:
                                  leave:     Do not remove, but allow destructive merges
                                  preserve:  Preserve the working directory
                                  remove:    Always remove the working directory
                                  tidyup:    Tidy up work directory after a successful build
        Overridden Masks
            Supported platforms ~amd64 ~arm ~x86

PKG_STATUS
    @pid = 12345
    @shell_out = OpenStruct.new(:stdout => @stdout,:stdin => @stdin,:stderr => @stderr,:status => @status,:exitstatus => 0)
  end

  context "when loading current resource" do
    it "should create a current resource with the name of the new_resource" do
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources package name to the new resources package name" do
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @current_resource.should_receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should run pkg info with the package name" do
      @provider.should_receive(:shell_out!).with("cave -L warning show #{@new_resource.package_name}").and_return(@shell_out)
      @provider.load_current_resource
    end

    it "should set the installed version to nil on the current resource if package state is not installed" do
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @current_resource.should_receive(:version).with(nil).and_return(true)
      @provider.load_current_resource
    end

    it "should set the installed version if package has one" do
      @stdout.replace(<<-INSTALLED)
* dev-scm/git
    ::arbor                   1.8.4.5(~) 1.8.5.5(~) 1.9.2(~)* {:0}
    ::installed               1.9.2 {:0}
    dev-scm/git-1.9.2:0::installed (system)
    Description
Git is a fast, scalable, distributed revision control system with an unusually
rich command set that provides both high-level operations and full access to internals
    Homepage                  http://git-scm.com/
    Summary                   A distributed VCS focused on speed, effectivity and real-world usability on large projects
    From repositories         arbor
    Installed time            Mon Apr 28 10:55:08 MSK 2014
    Installed using           paludis-1.4.2
    Licences                  GPL-2
    Options
        OPTIONS
            (-baselayout)     Install baselayout-1 init files
            (bash-completion) Enable bash-completion support
            (curl)            Adds support for client-side URL transfer library
            (-doc)            Adds extra documentation (API, Javadoc, etc)
            (emacs)           Install various Emacs libraries: git.el, git-blame.el and vc-git.el
            (-python)         Install helper scripts for git remote helpers, a compatibility layer with other SCMs
            (systemd)         Add support for the systemd init daemon (usually by installing units (configuration files)).
            (-tk)             Adds support for Tk GUI toolkit
            (-webdav)         Adds support for pushing using http:// and https:// transports
            (-xinetd)         Add support for the xinetd super-server
            (-zsh-completion) Install completion files for the Z shell
        git_remote_helpers
            (-bzr)            Install the Bazaar remote helper (e. g. git clone bzr::lp:gnuhello)
            (-mercurial)      Install the Mecurial remote helper (e. g. git clone hg::http://selenic.com/repo/hello)
        Build Options
            -trace            Trace actions executed by the package (very noisy, for debugging broken builds only)
    dev-scm/git-1.9.2:0::arbor (system)
    Homepage                  http://git-scm.com/
    Summary                   A distributed VCS focused on speed, effectivity and real-world usability on large projects
    Description               Git is a fast, scalable, distributed revision control system with an unusually rich command set that provides both high-level operations and full access to internals
    Options
        OPTIONS
            -baselayout       Install baselayout-1 init files
            bash-completion   Enable bash-completion support
            curl              Adds support for client-side URL transfer library
            -doc              Adds extra documentation (API, Javadoc, etc)
            emacs             Install various Emacs libraries: git.el, git-blame.el and vc-git.el
            -python           Install helper scripts for git remote helpers, a compatibility layer with other SCMs
            systemd           Add support for the systemd init daemon (usually by installing units (configuration files)).
            -tk               Adds support for Tk GUI toolkit
            -webdav           Adds support for pushing using http:// and https:// transports
            -xinetd           Add support for the xinetd super-server
            -zsh-completion   Install completion files for the Z shell
        git_remote_helpers
            -bzr              Install the Bazaar remote helper (e. g. git clone bzr::lp:gnuhello)
            -mercurial        Install the Mecurial remote helper (e. g. git clone hg::http://selenic.com/repo/hello)
        Build Options
            symbols=split     How to handle debug symbols in installed files
                              Permitted values:
                                  compress:  Split and compress debug symbols
                                  preserve:  Preserve debug symbols
                                  split:     Split debug symbols
                                  strip:     Strip debug symbols
            jobs=3            How many jobs the package's build system should use, where supported
                              Should be an integer >= 1
            -dwarf_compress   Compress DWARF2+ debug information
            -recommended_tests Run tests considered by the package to be recommended
            -trace            Trace actions executed by the package (very noisy, for debugging broken builds only)
            work=tidyup       Whether to preserve or remove working directories
                              Permitted values:
                                  leave:     Do not remove, but allow destructive merges
                                  preserve:  Preserve the working directory
                                  remove:    Always remove the working directory
                                  tidyup:    Tidy up work directory after a successful build
        Overridden Masks
            Supported platforms ~amd64 ~arm ~x86

INSTALLED
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @provider.load_current_resource
      @current_resource.version.should == "1.9.2"
      @provider.candidate_version.should eql("1.9.2")
    end

    it "should return the current resource" do
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @provider.load_current_resource.should eql(@current_resource)
    end
  end

  context "when installing a package" do
    it "should run pkg install with the package name and version" do
      @provider.should_receive(:shell_out!).with("cave -L warning resolve -x \"=dev-scm/git-1.9.2\"")
      @provider.install_package("dev-scm/git", "1.9.2")
    end


    it "should run pkg install with the package name and version and options if specified" do
      @provider.should_receive(:shell_out!).with("cave -L warning resolve -x --preserve-world \"=dev-scm/git-1.9.2\"")
      @new_resource.stub(:options).and_return("--preserve-world")
      @provider.install_package("dev-scm/git", "1.9.2")
    end

    it "should not contain invalid characters for the version string" do
      @stdout.replace(<<-PKG_STATUS)
* sys-process/lsof
    ::arbor                   4.87(~)* {:0}
    sys-process/lsof-4.87:0::arbor
    Homepage                  http://people.freebsd.org/~abe/
    Summary                   List open files for running UNIX processes
    Options
        Build Options
            symbols=split     How to handle debug symbols in installed files
                              Permitted values:
                                  compress:  Split and compress debug symbols
                                  preserve:  Preserve debug symbols
                                  split:     Split debug symbols
                                  strip:     Strip debug symbols
            jobs=3            How many jobs the package's build system should use, where supported
                              Should be an integer >= 1
            -dwarf_compress   Compress DWARF2+ debug information
            -recommended_tests Run tests considered by the package to be recommended
            -trace            Trace actions executed by the package (very noisy, for debugging broken builds only)
            work=tidyup       Whether to preserve or remove working directories
                              Permitted values:
                                  leave:     Do not remove, but allow destructive merges
                                  preserve:  Preserve the working directory
                                  remove:    Always remove the working directory
                                  tidyup:    Tidy up work directory after a successful build
        Overridden Masks
            Supported platforms ~amd64 ~x86

PKG_STATUS
      @provider.should_receive(:shell_out!).with("cave -L warning resolve -x \"=sys-process/lsof-4.87\"")
      @provider.install_package("sys-process/lsof", "4.87")
    end

    it "should not include the human-readable version in the candidate_version" do
      @stdout.replace(<<-PKG_STATUS)
* sys-process/lsof
    ::arbor                   4.87(~)* {:0}
    sys-process/lsof-4.87:0::arbor
    Homepage                  http://people.freebsd.org/~abe/
    Summary                   List open files for running UNIX processes
    Options
        Build Options
            symbols=split     How to handle debug symbols in installed files
                              Permitted values:
                                  compress:  Split and compress debug symbols
                                  preserve:  Preserve debug symbols
                                  split:     Split debug symbols
                                  strip:     Strip debug symbols
            jobs=3            How many jobs the package's build system should use, where supported
                              Should be an integer >= 1
            -dwarf_compress   Compress DWARF2+ debug information
            -recommended_tests Run tests considered by the package to be recommended
            -trace            Trace actions executed by the package (very noisy, for debugging broken builds only)
            work=tidyup       Whether to preserve or remove working directories
                              Permitted values:
                                  leave:     Do not remove, but allow destructive merges
                                  preserve:  Preserve the working directory
                                  remove:    Always remove the working directory
                                  tidyup:    Tidy up work directory after a successful build
        Overridden Masks
            Supported platforms ~amd64 ~x86

PKG_STATUS
      @provider.should_receive(:shell_out!).and_return(@shell_out)
      @provider.load_current_resource
      @current_resource.version.should be_nil
      @provider.candidate_version.should eql("4.87")
    end
  end

  context "when upgrading a package" do
    it "should run pkg install with the package name and version" do
      @provider.should_receive(:shell_out!).with("cave -L warning resolve -x \"=dev-scm/git-1.9.2\"")
      @provider.upgrade_package("dev-scm/git", "1.9.2")
    end
  end

  context "when uninstalling a package" do
    it "should run pkg uninstall with the package name and version" do
      @provider.should_receive(:shell_out!).with("cave -L warning uninstall -x \"=dev-scm/git-1.9.2\"")
      @provider.remove_package("dev-scm/git", "1.9.2")
    end

  end
end
