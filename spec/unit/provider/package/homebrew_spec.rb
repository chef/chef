#
# Author:: Joshua Timberman (<joshua@chef.io>)
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

describe Chef::Provider::Package::Homebrew do
  let(:default_brew_path) { "/usr/local/bin/brew" }
  let(:node) { Chef::Node.new }
  let(:new_resource) { Chef::Resource::HomebrewPackage.new(%w{emacs vim}) }
  let(:current_resource) { Chef::Resource::HomebrewPackage.new("emacs, vim") }
  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::Package::Homebrew.new(new_resource, run_context)
  end

  let(:homebrew_uid) { 1001 }
  let(:brew_cmd_output_data) { '[{"name":"emacs","full_name":"emacs","oldname":null,"aliases":[],"versioned_formulae":[],"desc":"GNU Emacs text editor","homepage":"https://www.gnu.org/software/emacs/","versions":{"stable":"26.3","devel":null,"head":"HEAD","bottle":true},"urls":{"stable":{"url":"https://ftp.gnu.org/gnu/emacs/emacs-26.3.tar.xz","tag":null,"revision":null}},"revision":0,"version_scheme":0,"bottle":{"stable":{"rebuild":0,"cellar":"/usr/local/Cellar","prefix":"/usr/local","root_url":"https://homebrew.bintray.com/bottles","files":{"catalina":{"url":"https://homebrew.bintray.com/bottles/emacs-26.3.catalina.bottle.tar.gz","sha256":"9ab33f4386ca5f7326a8c28da1324556ec990f682a7ca88641203da0b42dbdae"},"mojave":{"url":"https://homebrew.bintray.com/bottles/emacs-26.3.mojave.bottle.tar.gz","sha256":"8162a26246de7db44c53ea0d0ef0a806140318d19c69e8e5e33aa88ce7e823a8"},"high_sierra":{"url":"https://homebrew.bintray.com/bottles/emacs-26.3.high_sierra.bottle.tar.gz","sha256":"6a2629b6deddf99f81abb1990ecd6c87f0242a0eecbb6b6c2e4c3540e421d4c4"},"sierra":{"url":"https://homebrew.bintray.com/bottles/emacs-26.3.sierra.bottle.tar.gz","sha256":"2a47477e71766d7dd6b16c29ad5ba71817ed80d06212e3261ef3c776e7e9f5a2"}}}},"keg_only":false,"bottle_disabled":false,"options":[],"build_dependencies":["pkg-config"],"dependencies":["gnutls"],"recommended_dependencies":[],"optional_dependencies":[],"uses_from_macos":["libxml2","ncurses"],"requirements":[],"conflicts_with":[],"caveats":null,"installed":[],"linked_keg":null,"pinned":false,"outdated":false},{"name":"vim","full_name":"vim","oldname":null,"aliases":[],"versioned_formulae":[],"desc":"Vi \'workalike\' with many additional features","homepage":"https://www.vim.org/","versions":{"stable":"8.2.0550","devel":null,"head":"HEAD","bottle":true},"urls":{"stable":{"url":"https://github.com/vim/vim/archive/v8.2.0550.tar.gz","tag":null,"revision":null}},"revision":0,"version_scheme":0,"bottle":{"stable":{"rebuild":0,"cellar":"/usr/local/Cellar","prefix":"/usr/local","root_url":"https://homebrew.bintray.com/bottles","files":{"catalina":{"url":"https://homebrew.bintray.com/bottles/vim-8.2.0550.catalina.bottle.tar.gz","sha256":"8f9252500775aa85d8f826af30ca9e1118a56145fc2f961c37abed48bf78cf6b"},"mojave":{"url":"https://homebrew.bintray.com/bottles/vim-8.2.0550.mojave.bottle.tar.gz","sha256":"7566c83b770f3e8c4d4b462a39e5eb26609b37a8f8db6690a2560a3e22ded6b6"},"high_sierra":{"url":"https://homebrew.bintray.com/bottles/vim-8.2.0550.high_sierra.bottle.tar.gz","sha256":"a76e517fc69bf67b6903cb82295bc085c5eb4b46b4659f034c694dd97d2ee2d9"}}}},"keg_only":false,"bottle_disabled":false,"options":[],"build_dependencies":[],"dependencies":["gettext","lua","perl","python","ruby"],"recommended_dependencies":[],"optional_dependencies":[],"uses_from_macos":["ncurses"],"requirements":[],"conflicts_with":["ex-vi","macvim"],"caveats":null,"installed":[{"version":"8.2.0550","used_options":[],"built_as_bottle":true,"poured_from_bottle":true,"runtime_dependencies":[{"full_name":"gettext","version":"0.20.1"},{"full_name":"lua","version":"5.3.5"},{"full_name":"perl","version":"5.30.2"},{"full_name":"gdbm","version":"1.18.1"},{"full_name":"openssl@1.1","version":"1.1.1f"},{"full_name":"readline","version":"8.0.4"},{"full_name":"sqlite","version":"3.31.1"},{"full_name":"xz","version":"5.2.5"},{"full_name":"python","version":"3.7.7"},{"full_name":"libyaml","version":"0.2.2"},{"full_name":"ruby","version":"2.7.1"}],"installed_as_dependency":false,"installed_on_request":true}],"linked_keg":"8.2.0550","pinned":false,"outdated":false}]' }

  let(:brew_info_data) do
    { "openssl@1.1" =>
      { "name" => "openssl@1.1",
       "full_name" => "openssl@1.1",
       "oldname" => nil,
       "aliases" => ["openssl"],
       "versioned_formulae" => [],
       "desc" => "Cryptography and SSL/TLS Toolkit",
       "homepage" => "https://openssl.org/",
       "versions" => { "stable" => "1.1.1f", "devel" => nil, "head" => nil, "bottle" => true },
       "urls" => { "stable" => { "url" => "https://www.openssl.org/source/openssl-1.1.1f.tar.gz", "tag" => nil, "revision" => nil } },
       "revision" => 0,
       "version_scheme" => 1,
       "bottle" =>
        { "stable" =>
          { "rebuild" => 0,
           "cellar" => "/usr/local/Cellar",
           "prefix" => "/usr/local",
           "root_url" => "https://homebrew.bintray.com/bottles",
           "files" =>
            { "catalina" => { "url" => "https://homebrew.bintray.com/bottles/openssl@1.1-1.1.1f.catalina.bottle.tar.gz", "sha256" => "724cd97c269952cdc28e24798e350fcf520a32c5985aeb26053ce006a09d8179" },
             "mojave" => { "url" => "https://homebrew.bintray.com/bottles/openssl@1.1-1.1.1f.mojave.bottle.tar.gz", "sha256" => "25ab844d2f14fc85c7f52958b4b89bdd2965bbd9c557445829eff6473f238744" },
             "high_sierra" => { "url" => "https://homebrew.bintray.com/bottles/openssl@1.1-1.1.1f.high_sierra.bottle.tar.gz", "sha256" => "27f26e2442222ac0565193fe0b86d8719559d776bcdd070d6113c16bb13accf6" } } } },
       "keg_only" => true,
       "bottle_disabled" => false,
       "options" => [],
       "build_dependencies" => [],
       "dependencies" => [],
       "recommended_dependencies" => [],
       "optional_dependencies" => [],
       "uses_from_macos" => [],
       "requirements" => [],
       "conflicts_with" => [],
       "caveats" =>
        "A CA file has been bootstrapped using certificates from the system\nkeychain. To add additional certificates, place .pem files in\n  $(brew --prefix)/etc/openssl@1.1/certs\n\nand run\n  $(brew --prefix)/opt/openssl@1.1/bin/c_rehash\n",
       "installed" => [{ "version" => "1.1.1a", "used_options" => [], "built_as_bottle" => true, "poured_from_bottle" => true, "runtime_dependencies" => [], "installed_as_dependency" => true, "installed_on_request" => false }],
       "linked_keg" => nil,
       "pinned" => false,
       "outdated" => false },
     "kubernetes-cli" =>
      { "name" => "kubernetes-cli",
       "full_name" => "kubernetes-cli",
       "oldname" => nil,
       "aliases" => ["kubectl"],
       "versioned_formulae" => [],
       "desc" => "Kubernetes command-line interface",
       "homepage" => "https://kubernetes.io/",
       "versions" => { "stable" => "1.18.1", "devel" => nil, "head" => "HEAD", "bottle" => true },
      "urls" => { "stable" => { "url" => "https://github.com/kubernetes/kubernetes.git", "tag" => "v1.18.1", "revision" => "7879fc12a63337efff607952a323df90cdc7a335" } },
       "revision" => 0,
       "version_scheme" => 0,
       "bottle" =>
        { "stable" =>
          { "rebuild" => 0,
           "cellar" => ":any_skip_relocation",
           "prefix" => "/usr/local",
           "root_url" => "https://homebrew.bintray.com/bottles",
           "files" =>
            { "catalina" => { "url" => "https://homebrew.bintray.com/bottles/kubernetes-cli-1.18.1.catalina.bottle.tar.gz", "sha256" => "0b3d688ee458b70b914a37a4ba867e202c6e71190d0c40a27f84628aec744749" },
             "mojave" => { "url" => "https://homebrew.bintray.com/bottles/kubernetes-cli-1.18.1.mojave.bottle.tar.gz", "sha256" => "21fddfc86ec6d3e4f7ea787310b0fafd845d368de37524569bbe45938b18ba09" },
             "high_sierra" => { "url" => "https://homebrew.bintray.com/bottles/kubernetes-cli-1.18.1.high_sierra.bottle.tar.gz", "sha256" => "1e20dcd177fd16b862b2432950984807b048cca5879c27bec59e85590f40eece" } } } },
       "keg_only" => false,
       "bottle_disabled" => false,
       "options" => [],
       "build_dependencies" => ["go"],
       "dependencies" => [],
       "recommended_dependencies" => [],
       "optional_dependencies" => [],
       "uses_from_macos" => [],
       "requirements" => [],
       "conflicts_with" => [],
       "caveats" => nil,
       "installed" => [],
       "linked_keg" => nil,
       "pinned" => false,
       "outdated" => false },
     "vim" =>
      { "name" => "vim",
       "full_name" => "vim",
       "oldname" => nil,
       "aliases" => [],
       "versioned_formulae" => [],
       "desc" => "Vi 'workalike' with many additional features",
       "homepage" => "https://www.vim.org/",
       "versions" => { "stable" => "8.2.0550", "devel" => nil, "head" => "HEAD", "bottle" => true },
       "urls" => { "stable" => { "url" => "https://github.com/vim/vim/archive/v8.2.0550.tar.gz", "tag" => nil, "revision" => nil } },
       "revision" => 0,
       "version_scheme" => 0,
       "bottle" =>
        { "stable" =>
          { "rebuild" => 0,
           "cellar" => "/usr/local/Cellar",
           "prefix" => "/usr/local",
           "root_url" => "https://homebrew.bintray.com/bottles",
           "files" =>
            { "catalina" => { "url" => "https://homebrew.bintray.com/bottles/vim-8.2.0550.catalina.bottle.tar.gz", "sha256" => "8f9252500775aa85d8f826af30ca9e1118a56145fc2f961c37abed48bf78cf6b" },
                    "mojave" => { "url" => "https://homebrew.bintray.com/bottles/vim-8.2.0550.mojave.bottle.tar.gz", "sha256" => "7566c83b770f3e8c4d4b462a39e5eb26609b37a8f8db6690a2560a3e22ded6b6" },
             "high_sierra" => { "url" => "https://homebrew.bintray.com/bottles/vim-8.2.0550.high_sierra.bottle.tar.gz", "sha256" => "a76e517fc69bf67b6903cb82295bc085c5eb4b46b4659f034c694dd97d2ee2d9" } } } },
       "keg_only" => false,
       "bottle_disabled" => false,
       "options" => [],
       "build_dependencies" => [],
       "dependencies" => %w{gettext lua perl python ruby},
       "recommended_dependencies" => [],
       "optional_dependencies" => [],
       "uses_from_macos" => ["ncurses"],
       "requirements" => [],
       "conflicts_with" => %w{ex-vi macvim},
       "caveats" => nil,
       "installed" =>
        [{ "version" => "8.2.0550",
          "used_options" => [],
          "built_as_bottle" => true,
          "poured_from_bottle" => true,
          "runtime_dependencies" =>
           [{ "full_name" => "gettext", "version" => "0.20.1" },
            { "full_name" => "lua", "version" => "5.3.5" },
            { "full_name" => "perl", "version" => "5.30.2" },
            { "full_name" => "gdbm", "version" => "1.18.1" },
            { "full_name" => "openssl@1.1", "version" => "1.1.1f" },
            { "full_name" => "readline", "version" => "8.0.4" },
            { "full_name" => "sqlite", "version" => "3.31.1" },
            { "full_name" => "xz", "version" => "5.2.5" },
            { "full_name" => "python", "version" => "3.7.7" },
            { "full_name" => "libyaml", "version" => "0.2.2" },
            { "full_name" => "ruby", "version" => "2.7.1" }],
          "installed_as_dependency" => false,
          "installed_on_request" => true }],
       "linked_keg" => "8.2.0550",
       "pinned" => false,
       "outdated" => false },
     "curl" =>
      { "name" => "curl",
       "full_name" => "curl",
       "oldname" => nil,
       "aliases" => [],
       "versioned_formulae" => [],
       "desc" => "Get a file from an HTTP, HTTPS or FTP server",
       "homepage" => "https://curl.haxx.se/",
       "versions" => { "stable" => "7.69.1", "devel" => nil, "head" => "HEAD", "bottle" => true },
       "urls" => { "stable" => { "url" => "https://curl.haxx.se/download/curl-7.69.1.tar.bz2", "tag" => nil, "revision" => nil } },
       "revision" => 0,
       "version_scheme" => 0,
       "bottle" =>
         { "stable" =>
          { "rebuild" => 0,
           "cellar" => ":any",
           "prefix" => "/usr/local",
           "root_url" => "https://homebrew.bintray.com/bottles",
           "files" =>
            { "catalina" => { "url" => "https://homebrew.bintray.com/bottles/curl-7.69.1.catalina.bottle.tar.gz", "sha256" => "400500fede02f9335bd38c16786b2bbf5e601e358dfac8c21e363d2a8fdd8fac" },
             "mojave" => { "url" => "https://homebrew.bintray.com/bottles/curl-7.69.1.mojave.bottle.tar.gz", "sha256" => "f082c275f9af1e8e93be12b63a1aff659ba6efa48c8528a97e26c9858a6f95b6" },
             "high_sierra" => { "url" => "https://homebrew.bintray.com/bottles/curl-7.69.1.high_sierra.bottle.tar.gz", "sha256" => "ad023093c252799a4c60646a149bfe14ffa6984817cf463a6f0e98f6551057fe" } } } },
       "keg_only" => true,
       "bottle_disabled" => false,
       "options" => [],
       "build_dependencies" => ["pkg-config"],
       "dependencies" => [],
       "recommended_dependencies" => [],
       "optional_dependencies" => [],
       "uses_from_macos" => ["openssl@1.1", "zlib"],
       "requirements" => [],
       "conflicts_with" => [],
       "caveats" => nil,
       "installed" => [],
       "linked_keg" => nil,
       "pinned" => false,
       "outdated" => false } }
  end

  describe "#load_current_resource" do
    before(:each) do
      allow(provider).to receive(:installed_version).and_return(nil)
      allow(provider).to receive(:available_version).and_return("1.0")
    end

    it "creates a current resource with the name of the new resource" do
      provider.load_current_resource
      expect(provider.current_resource).to be_a(Chef::Resource::Package)
      expect(provider.current_resource.name).to eql("emacs, vim")
    end

    it "creates a current resource with the version if the package is installed" do
      expect(provider).to receive(:get_current_versions).and_return(["1.0", "2.0"])
      provider.load_current_resource
      expect(provider.current_resource.version).to eql(["1.0", "2.0"])
    end

    it "creates a current resource with a nil version if the package is not installed" do
      provider.load_current_resource
      expect(provider.current_resource.version).to eq([nil, nil])
    end

    it "sets a candidate version if one exists" do
      provider.load_current_resource
      expect(provider.candidate_version).to eql(["1.0", "1.0"])
    end
  end

  describe "#brew_info" do
    it "returns a hash of data per package" do
      allow(provider).to receive(:brew_cmd_output).and_return(brew_cmd_output_data)
      expect(provider.brew_info).to have_key("vim")
    end

    it "returns empty hash for packages if they lack data" do
      new_resource.package_name %w{bogus}
      allow(provider).to receive(:brew_cmd_output).and_return("")
      expect(provider.brew_info).to eq("bogus" => {})
    end
  end

  describe "#installed_version" do
    it "returns the latest version from brew info if the package is keg only" do
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
      expect(provider.installed_version("openssl@1.1")).to eql("1.1.1a")
    end

    it "returns the linked keg version if the package is not keg only" do
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
      expect(provider.installed_version("vim")).to eql("8.2.0550")
    end

    it "returns nil if the package is not installed" do
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
      expect(provider.installed_version("kubernetes-cli")).to be_nil
    end

    it "returns nil if the package is keg only and not installed" do
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
      expect(provider.installed_version("curl")).to be_nil
    end

    it "returns the version if a package alias is given" do
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
      expect(provider.installed_version("openssl")).to eql("1.1.1a")
    end
  end

  describe "#available_version" do
    it "returns version of package when exact name given" do
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
      expect(provider.available_version("openssl@1.1")).to eql("1.1.1f")
    end

    it "returns version of package when alias is given" do
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
      expect(provider.available_version("openssl")).to eql("1.1.1f")
    end

    it "returns nil if the package is not installed" do
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
      expect(provider.available_version("bogus")).to be_nil
    end
  end

  describe "#brew_cmd_output" do
    before do
      expect(provider).to receive(:find_homebrew_uid).and_return(homebrew_uid)
      expect(Etc).to receive(:getpwuid).with(homebrew_uid).and_return(OpenStruct.new(name: "name", dir: "/"))
    end

    it "passes a single pkg to the brew command and return stdout" do
      allow(provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: "zombo"))
      allow(provider).to receive(:homebrew_bin_path).and_return(default_brew_path)
      expect(provider.brew_cmd_output).to eql("zombo")
    end

    it "takes multiple arguments as an array" do
      allow(provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: "homestarrunner"))
      allow(provider).to receive(:homebrew_bin_path).and_return(default_brew_path)
      expect(provider.brew_cmd_output("info", "opts", "bananas")).to eql("homestarrunner")
    end

    context "when new_resource is Package" do
      let(:new_resource) { Chef::Resource::Package.new("emacs") }

      it "does not try to read homebrew_user from Package, which does not have it" do
        allow(provider).to receive(:shell_out!).and_return(OpenStruct.new(stdout: "zombo"))
        allow(provider).to receive(:homebrew_bin_path).and_return(default_brew_path)
        expect(provider.brew_cmd_output).to eql("zombo")
      end
    end
  end

  describe "resource actions" do
    before(:each) do
      provider.current_resource = current_resource
      allow(provider).to receive(:brew_info).and_return(brew_info_data)
    end

    describe "install" do
      it "calls brew_cmd_output to install only the necessary packages" do
        new_resource.package_name %w{curl openssl}
        expect(provider).to receive(:brew_cmd_output).with("install", nil, ["curl"])
        provider.run_action(:install)
      end

      it "does not do anything if all the packages are already installed" do
        new_resource.package_name %w{vim openssl}
        expect(provider).not_to receive(:brew_cmd_output)
        provider.run_action(:install)
      end

      it "uses options to the brew command if specified" do
        new_resource.package_name "curl"
        new_resource.options "--cocoa"
        expect(provider).to receive(:brew_cmd_output).with("install", ["--cocoa"], ["curl"])
        provider.run_action(:install)
      end
    end

    describe "upgrade" do
      it "calls #brew_cmd_output to upgrade the packages" do
        new_resource.package_name %w{openssl}
        allow(provider.current_resource).to receive(:version).and_return(["1.0.1a"])
        expect(provider).to receive(:brew_cmd_output).with("upgrade", nil, ["openssl"])
        provider.run_action(:upgrade)
      end

      it "calls #brew_cmd_output to both upgrade and install the packages as necessary" do
        new_resource.package_name %w{openssl kubernetes-cli}
        allow(provider.current_resource).to receive(:version).and_return(["1.0.1a", nil])
        expect(provider).to receive(:brew_cmd_output).with("upgrade", nil, ["openssl"])
        expect(provider).to receive(:brew_cmd_output).with("install", nil, ["kubernetes-cli"])
        provider.run_action(:upgrade)
      end

      it "uses options to the brew command if specified" do
        new_resource.package_name %w{openssl}
        allow(provider.current_resource).to receive(:version).and_return(["1.0.1a"])
        allow(provider).to receive(:brew_info).and_return(brew_info_data)
        new_resource.options "--cocoa"
        expect(provider).to receive(:brew_cmd_output).with("upgrade", [ "--cocoa" ], ["openssl"])
        provider.run_action(:upgrade)
      end
    end

    describe "remove" do
      it "calls #brew_cmd_output to uninstall the packages" do
        new_resource.package_name %w{curl openssl}
        expect(provider).to receive(:brew_cmd_output).with("uninstall", nil, %w{curl openssl})
        provider.run_action(:remove)
      end

      it "does not do anything if the package is not installed" do
        new_resource.package_name %w{kubernetes-cli}
        expect(provider).not_to receive(:brew_cmd_output)
        provider.run_action(:remove)
      end
    end

    describe "purge" do
      it "call #brew_cmd_output to uninstall --force the packages" do
        new_resource.package_name %w{curl openssl}
        expect(provider).to receive(:brew_cmd_output).with("uninstall", "--force", nil, %w{curl openssl})
        provider.run_action(:purge)
      end

      it "does not do anything if the package is not installed" do
        new_resource.package_name %w{kubernetes-cli}
        expect(provider).not_to receive(:brew_cmd_output)
        provider.run_action(:purge)
      end
    end
  end
end
