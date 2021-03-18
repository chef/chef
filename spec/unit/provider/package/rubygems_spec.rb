#
# Author:: David Balatero (dbalatero@gmail.com)
#
# Copyright:: Copyright 2009-2016, David Balatero
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

module GemspecBackcompatCreator
  def gemspec(name, version)
    if Gem::Specification.new.method(:initialize).arity == 0
      Gem::Specification.new { |s| s.name = name; s.version = version }
    else
      Gem::Specification.new(name, version)
    end
  end
end

# this is a global variable we construct of the highest rspec-core version which is installed, using APIs which
# will break out of the bundle -- and done this way so that we can mock all these internal Gem APIs later...
class RspecVersionString
  def self.rspec_version_string
    @rspec_version_string ||= begin
                                stubs = Gem::Specification.send(:installed_stubs, Gem::Specification.dirs, "rspec-core-*.gemspec")
                                stubs.select! { |stub| stub.name == "rspec-core" && Gem::Dependency.new("rspec-core", ">= 0").requirement.satisfied_by?(stub.version) }
                                stubs.max_by(&:version).version.to_s
                              end
  end
end
RspecVersionString.rspec_version_string

require "spec_helper"
require "ostruct"

describe Chef::Provider::Package::Rubygems::CurrentGemEnvironment do
  include GemspecBackcompatCreator

  let(:logger) { double("Mixlib::Log::Child").as_null_object }
  before do
    @gem_env = Chef::Provider::Package::Rubygems::CurrentGemEnvironment.new
    allow(@gem_env).to receive(:logger).and_return(logger)

    WebMock.disable_net_connect!
  end

  it "determines the gem paths from the in memory rubygems" do
    expect(@gem_env.gem_paths).to eq(Gem.path)
  end

  it "determines the installed versions of gems from Gem.source_index" do
    gems = [gemspec("rspec-core", Gem::Version.new("1.2.9")), gemspec("rspec-core", Gem::Version.new("1.3.0"))]
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new("2.7")
      expect(Gem::Specification).to receive(:dirs).and_return(["/path/to/gems/specifications", "/another/path/to/gems/specifications"])
      expect(Gem::Specification).to receive(:installed_stubs).with(["/path/to/gems/specifications", "/another/path/to/gems/specifications"], "rspec-core-*.gemspec").and_return(gems)
    else # >= Rubygems 1.8 behavior
      expect(Gem::Specification).to receive(:find_all_by_name).with("rspec-core", Gem::Dependency.new("rspec-core").requirement).and_return(gems)
    end
    expect(@gem_env.installed_versions(Gem::Dependency.new("rspec-core", nil))).to eq(gems)
  end

  it "determines the installed versions of gems from the source index (part2: the unmockening)" do
    expected = ["rspec-core", Gem::Version.new( RspecVersionString.rspec_version_string )]
    actual = @gem_env.installed_versions(Gem::Dependency.new("rspec-core", nil)).map { |spec| [spec.name, spec.version] }
    expect(actual).to include(expected)
  end

  it "yields to a block with an alternate source list set" do
    sources_in_block = nil
    normal_sources = Gem.sources
    begin
      @gem_env.with_gem_sources("http://gems.example.org") do
        sources_in_block = Gem.sources
        raise "sources should be reset even in case of an error"
      end
    rescue RuntimeError
    end
    expect(sources_in_block).to eq(%w{http://gems.example.org})
    expect(Gem.sources).to eq(normal_sources)
  end

  it "it doesnt alter the gem sources if none are set" do
    sources_in_block = nil
    normal_sources = Gem.sources
    begin
      @gem_env.with_gem_sources(nil) do
        sources_in_block = Gem.sources
        raise "sources should be reset even in case of an error"
      end
    rescue RuntimeError
    end
    expect(sources_in_block).to eq(normal_sources)
    expect(Gem.sources).to eq(normal_sources)
  end

  context "new default rubygems behavior" do
    before do
      Chef::Config[:rubygems_cache_enabled] = false

      dep_installer = Gem::DependencyInstaller.new
      expect(dep_installer).not_to receive(:find_gems_with_sources)
      allow(@gem_env).to receive(:dependency_installer).and_return(dep_installer)
    end

    it "finds a matching gem candidate version on rubygems 2.0.0+" do
      stub_request(:head, "https://index.rubygems.org/")
        .to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://index.rubygems.org/info/sexp_processor")
        .to_return(status: 200, body: File.binread(File.join(CHEF_SPEC_DATA, "rubygems.org", "sexp_processor-info")))
      stub_request(:get, "https://index.rubygems.org/quick/Marshal.4.8/sexp_processor-4.15.1.gemspec.rz")
        .to_return(status: 200, body: File.binread(File.join(CHEF_SPEC_DATA, "rubygems.org", "sexp_processor-4.15.1.gemspec.rz")))

      dep = Gem::Dependency.new("sexp_processor", ">= 0")
      expect(@gem_env.candidate_version_from_remote(dep)).to be_kind_of(Gem::Version)
    end

    it "gives the candidate version as nil if none is found" do
      stub_request(:head, "https://index.rubygems.org/")
        .to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://index.rubygems.org/info/nonexistent_gem")
        .to_return(status: 200, body: File.binread(File.join(CHEF_SPEC_DATA, "rubygems.org", "nonexistent_gem-info")))

      dep = Gem::Dependency.new("nonexistent_gem", ">= 0")
      expect(@gem_env.candidate_version_from_remote(dep)).to be_nil
    end

    it "finds a matching gem from a specific gemserver when explicit sources are given (to a server that doesn't respond to api requests)" do
      stub_request(:head, "https://rubygems2.org/")
        .to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://rubygems2.org/info/sexp_processor")
        .to_return(status: 200, body: File.binread(File.join(CHEF_SPEC_DATA, "rubygems.org", "sexp_processor-info")))
      stub_request(:get, "https://rubygems2.org/quick/Marshal.4.8/sexp_processor-4.15.1.gemspec.rz")
        .to_return(status: 200, body: File.binread(File.join(CHEF_SPEC_DATA, "rubygems.org", "sexp_processor-4.15.1.gemspec.rz")))

      dep = Gem::Dependency.new("sexp_processor", ">= 0")
      expect(@gem_env.candidate_version_from_remote(dep, "https://rubygems2.org")).to be_kind_of(Gem::Version)
    end
  end

  context "old rubygems caching behavior" do
    before do
      Chef::Config[:rubygems_cache_enabled] = true

      stub_request(:get, "https://rubygems.org/latest_specs.4.8.gz")
        .to_return(status: 200, body: File.binread(File.join(CHEF_SPEC_DATA, "rubygems.org", "latest_specs.4.8.gz")))
    end

    it "finds a matching gem candidate version on rubygems 2.0.0+" do
      stub_request(:get, "https://rubygems.org/quick/Marshal.4.8/sexp_processor-4.15.1.gemspec.rz")
        .to_return(status: 200, body: File.binread(File.join(CHEF_SPEC_DATA, "rubygems.org", "sexp_processor-4.15.1.gemspec.rz")))

      dep = Gem::Dependency.new("sexp_processor", ">= 0")
      expect(@gem_env.candidate_version_from_remote(dep)).to be_kind_of(Gem::Version)
    end

    it "gives the candidate version as nil if none is found" do
      dep = Gem::Dependency.new("lksdjflksdjflsdkfj", ">= 0")
      expect(@gem_env.candidate_version_from_remote(dep)).to be_nil
    end

    it "finds a matching gem from a specific gemserver when explicit sources are given" do
      stub_request(:get, "https://rubygems.org/quick/Marshal.4.8/sexp_processor-4.15.1.gemspec.rz")
        .to_return(status: 200, body: File.binread(File.join(CHEF_SPEC_DATA, "rubygems.org", "sexp_processor-4.15.1.gemspec.rz")))

      dep = Gem::Dependency.new("sexp_processor", ">= 0")
      expect(@gem_env.candidate_version_from_remote(dep, "http://rubygems2.org")).to be_kind_of(Gem::Version)
    end
  end

  it "finds a matching candidate version from a .gem file when the path to the gem is supplied" do
    location = CHEF_SPEC_DATA + "/gems/chef-integration-test-0.1.0.gem"
    expect(@gem_env.candidate_version_from_file(Gem::Dependency.new("chef-integration-test", ">= 0"), location)).to eq(Gem::Version.new("0.1.0"))
    expect(@gem_env.candidate_version_from_file(Gem::Dependency.new("chef-integration-test", ">= 0.2.0"), location)).to be_nil
  end

  it "installs a gem with a hash of options for the dependency installer" do
    dep_installer = Gem::DependencyInstaller.new
    expect(@gem_env).to receive(:dependency_installer).with(install_dir: "/foo/bar").and_return(dep_installer)
    expect(@gem_env).to receive(:with_gem_sources).with("http://gems.example.com").and_yield
    expect(dep_installer).to receive(:install).with(Gem::Dependency.new("rspec", ">= 0"))
    @gem_env.install(Gem::Dependency.new("rspec", ">= 0"), install_dir: "/foo/bar", sources: ["http://gems.example.com"])
  end

  it "builds an uninstaller for a gem with options set to avoid requiring user input" do
    # default options for uninstaller should be:
    # :ignore => true, :executables => true
    expect(Gem::Uninstaller).to receive(:new).with("rspec", ignore: true, executables: true)
    @gem_env.uninstaller("rspec")
  end

  it "uninstalls all versions of a gem" do
    uninstaller = double("gem uninstaller")
    expect(uninstaller).to receive(:uninstall)
    expect(@gem_env).to receive(:uninstaller).with("rspec", all: true).and_return(uninstaller)
    @gem_env.uninstall("rspec")
  end

  it "uninstalls a specific version of a gem" do
    uninstaller = double("gem uninstaller")
    expect(uninstaller).to receive(:uninstall)
    expect(@gem_env).to receive(:uninstaller).with("rspec", version: "1.2.3").and_return(uninstaller)
    @gem_env.uninstall("rspec", "1.2.3")
  end

end

describe Chef::Provider::Package::Rubygems::AlternateGemEnvironment do
  include GemspecBackcompatCreator

  before do
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.gempath_cache.clear
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache.clear
    @gem_env = Chef::Provider::Package::Rubygems::AlternateGemEnvironment.new("/usr/weird/bin/gem")
  end

  it "determines the gem paths from shelling out to gem env" do
    gem_env_output = ["/path/to/gems", "/another/path/to/gems"].join(File::PATH_SEPARATOR)
    shell_out_result = OpenStruct.new(stdout: gem_env_output)
    expect(@gem_env).to receive(:shell_out_compacted!).with("/usr/weird/bin/gem env gempath").and_return(shell_out_result)
    expect(@gem_env.gem_paths).to eq(["/path/to/gems", "/another/path/to/gems"])
  end

  it "caches the gempaths by gem_binary" do
    gem_env_output = ["/path/to/gems", "/another/path/to/gems"].join(File::PATH_SEPARATOR)
    shell_out_result = OpenStruct.new(stdout: gem_env_output)
    expect(@gem_env).to receive(:shell_out_compacted!).with("/usr/weird/bin/gem env gempath").and_return(shell_out_result)
    expected = ["/path/to/gems", "/another/path/to/gems"]
    expect(@gem_env.gem_paths).to eq(["/path/to/gems", "/another/path/to/gems"])
    expect(Chef::Provider::Package::Rubygems::AlternateGemEnvironment.gempath_cache["/usr/weird/bin/gem"]).to eq(expected)
  end

  it "uses the cached result for gem paths when available" do
    expect(@gem_env).not_to receive(:shell_out_compacted!)
    expected = ["/path/to/gems", "/another/path/to/gems"]
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.gempath_cache["/usr/weird/bin/gem"] = expected
    expect(@gem_env.gem_paths).to eq(["/path/to/gems", "/another/path/to/gems"])
  end

  it "builds the gems source index from the gem paths" do
    allow(@gem_env).to receive(:gem_paths).and_return(["/path/to/gems", "/another/path/to/gems"])
    @gem_env.gem_specification
    expect(Gem::Specification.dirs).to eq([ "/path/to/gems/specifications", "/another/path/to/gems/specifications" ])
  end

  it "determines the installed versions of gems from the source index" do
    gems = [gemspec("rspec", Gem::Version.new("1.2.9")), gemspec("rspec", Gem::Version.new("1.3.0"))]
    rspec_dep = Gem::Dependency.new("rspec", nil)
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new("2.7")
      allow(@gem_env).to receive(:gem_specification).and_return(Gem::Specification)
      expect(Gem::Specification).to receive(:dirs).and_return(["/path/to/gems/specifications", "/another/path/to/gems/specifications"])
      expect(Gem::Specification).to receive(:installed_stubs).with(["/path/to/gems/specifications", "/another/path/to/gems/specifications"], "rspec-*.gemspec").and_return(gems)
    else # >= rubygems 1.8 behavior
      allow(@gem_env).to receive(:gem_specification).and_return(Gem::Specification)
      expect(@gem_env.gem_specification).to receive(:find_all_by_name).with(rspec_dep.name, rspec_dep.requirement).and_return(gems)
    end
    expect(@gem_env.installed_versions(Gem::Dependency.new("rspec", nil))).to eq(gems)
  end

  it "determines the installed versions of gems from the source index (part2: the unmockening)" do
    allow($stdout).to receive(:write)
    path_to_gem = if windows?
                    `where gem`.split[1]
                  else
                    `which gem`.strip
                  end
    skip("cant find your gem executable") if path_to_gem.empty?
    gem_env = Chef::Provider::Package::Rubygems::AlternateGemEnvironment.new(path_to_gem)
    expected = ["rspec-core", Gem::Version.new( RspecVersionString.rspec_version_string )]
    actual = gem_env.installed_versions(Gem::Dependency.new("rspec-core", nil)).map { |s| [s.name, s.version] }
    expect(actual).to include(expected)
  end

  it "detects when the target gem environment is the jruby platform" do
    gem_env_out = <<~JRUBY_GEM_ENV
      RubyGems Environment:
        - RUBYGEMS VERSION: 1.3.6
        - RUBY VERSION: 1.8.7 (2010-05-12 patchlevel 249) [java]
        - INSTALLATION DIRECTORY: /Users/you/.rvm/gems/jruby-1.5.0
        - RUBY EXECUTABLE: /Users/you/.rvm/rubies/jruby-1.5.0/bin/jruby
        - EXECUTABLE DIRECTORY: /Users/you/.rvm/gems/jruby-1.5.0/bin
        - RUBYGEMS PLATFORMS:
          - ruby
          - universal-java-1.6
        - GEM PATHS:
           - /Users/you/.rvm/gems/jruby-1.5.0
           - /Users/you/.rvm/gems/jruby-1.5.0@global
        - GEM CONFIGURATION:
           - :update_sources => true
           - :verbose => true
           - :benchmark => false
           - :backtrace => false
           - :bulk_threshold => 1000
           - "install" => "--env-shebang"
           - "update" => "--env-shebang"
           - "gem" => "--no-rdoc --no-ri"
           - :sources => ["https://rubygems.org/", "http://gems.github.com/"]
        - REMOTE SOURCES:
           - https://rubygems.org/
           - http://gems.github.com/
    JRUBY_GEM_ENV
    expect(@gem_env).to receive(:shell_out_compacted!).with("/usr/weird/bin/gem env").and_return(double("jruby_gem_env", stdout: gem_env_out))
    expected = ["ruby", Gem::Platform.new("universal-java-1.6")]
    expect(@gem_env.gem_platforms).to eq(expected)
    # it should also cache the result
    expect(Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache["/usr/weird/bin/gem"]).to eq(expected)
  end

  it "uses the cached result for gem platforms if available" do
    expect(@gem_env).not_to receive(:shell_out_compacted!)
    expected = ["ruby", Gem::Platform.new("universal-java-1.6")]
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache["/usr/weird/bin/gem"] = expected
    expect(@gem_env.gem_platforms).to eq(expected)
  end

  it "uses the current gem platforms when the target env is not jruby" do
    gem_env_out = <<~RBX_GEM_ENV
      RubyGems Environment:
        - RUBYGEMS VERSION: 1.3.6
        - RUBY VERSION: 1.8.7 (2010-05-14 patchlevel 174) [x86_64-apple-darwin10.3.0]
        - INSTALLATION DIRECTORY: /Users/ddeleo/.rvm/gems/rbx-1.0.0-20100514
        - RUBYGEMS PREFIX: /Users/ddeleo/.rvm/rubies/rbx-1.0.0-20100514
        - RUBY EXECUTABLE: /Users/ddeleo/.rvm/rubies/rbx-1.0.0-20100514/bin/rbx
        - EXECUTABLE DIRECTORY: /Users/ddeleo/.rvm/gems/rbx-1.0.0-20100514/bin
        - RUBYGEMS PLATFORMS:
          - ruby
          - x86_64-darwin-10
          - x86_64-rubinius-1.0
        - GEM PATHS:
           - /Users/ddeleo/.rvm/gems/rbx-1.0.0-20100514
           - /Users/ddeleo/.rvm/gems/rbx-1.0.0-20100514@global
        - GEM CONFIGURATION:
           - :update_sources => true
           - :verbose => true
           - :benchmark => false
           - :backtrace => false
           - :bulk_threshold => 1000
           - :sources => ["https://rubygems.org/", "http://gems.github.com/"]
           - "gem" => "--no-rdoc --no-ri"
        - REMOTE SOURCES:
           - https://rubygems.org/
           - http://gems.github.com/
    RBX_GEM_ENV
    expect(@gem_env).to receive(:shell_out_compacted!).with("/usr/weird/bin/gem env").and_return(double("rbx_gem_env", stdout: gem_env_out))
    expect(@gem_env.gem_platforms).to eq(Gem.platforms)
    expect(Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache["/usr/weird/bin/gem"]).to eq(Gem.platforms)
  end

  it "yields to a block while masquerading as a different gems platform" do
    original_platforms = Gem.platforms
    platforms_in_block = nil
    begin
      @gem_env.with_gem_platforms(["ruby", Gem::Platform.new("sparc64-java-1.7")]) do
        platforms_in_block = Gem.platforms
        raise "gem platforms should get set to the correct value even when an error occurs"
      end
    rescue RuntimeError
    end
    expect(platforms_in_block).to eq(["ruby", Gem::Platform.new("sparc64-java-1.7")])
    expect(Gem.platforms).to eq(original_platforms)
  end

end

describe Chef::Provider::Package::Rubygems do
  let(:target_version) { nil }
  let(:gem_name) { "rspec-core" }
  let(:gem_binary) { nil }
  let(:bindir) { "/usr/bin" }
  let(:options) { nil }
  let(:source) { nil }
  let(:include_default_source) { nil }

  let(:new_resource) do
    new_resource = Chef::Resource::GemPackage.new(gem_name)
    new_resource.version(target_version)
    new_resource.gem_binary(gem_binary) if gem_binary
    new_resource.options(options) if options
    new_resource.source(source) if source
    new_resource.include_default_source(include_default_source)
    new_resource
  end

  let(:current_resource) { nil }

  let(:provider) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    provider = Chef::Provider::Package::Rubygems.new(new_resource, run_context)
    if current_resource
      allow(provider).to receive(:load_current_resource)
      provider.current_resource = current_resource
    end
    provider
  end

  let(:gem_dep) { Gem::Dependency.new(gem_name, target_version) }

  before(:each) do
    # We choose detect omnibus via RbConfig::CONFIG['bindir'] in Chef::Provider::Package::Rubygems.new
    allow(RbConfig::CONFIG).to receive(:[]).with("bindir").and_return(bindir)
    # Rubygems uses these two interally
    allow(RbConfig::CONFIG).to receive(:[]).with("arch").and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with("ruby_install_name").and_call_original
    allow(File).to receive(:executable?).and_return false
    allow(File).to receive(:executable?).with("#{bindir}/gem").and_return true
    # XXX: we can't stub the provider object directly here because referencing it will create it and that
    # will break later tests that want to test the initialize method, so we stub any instance
    # (yet more evidence that initialize methods should be thin and do very little work)
    allow_any_instance_of(Chef::Provider::Package::Rubygems).to receive(:needs_nodocument?).and_return true
  end

  describe "when new_resource version is nil" do
    let(:target_version) { nil }

    it "target_version_already_installed? should return false so that we can search for candidates" do
      provider.load_current_resource
      expect(provider.target_version_already_installed?(provider.current_resource.version, new_resource.version)).to be_falsey
    end

    it "version_equals? should return false so that we can search for candidates" do
      provider.load_current_resource
      expect(provider.version_equals?(provider.current_resource.version, new_resource.version)).to be_falsey
    end
  end

  describe "when new_resource version is an rspec version" do
    let(:current_version) { RspecVersionString.rspec_version_string }
    let(:target_version) { current_version }

    it "triggers a gem configuration load so a later one will not stomp its config values" do
      _ = provider
      # ugly, is there a better way?
      expect(Gem.instance_variable_get(:@configuration)).not_to be_nil
    end

    it "uses the CurrentGemEnvironment implementation when no gem_binary_path is provided" do
      expect(provider.gem_env).to be_a_kind_of(Chef::Provider::Package::Rubygems::CurrentGemEnvironment)
    end

    context "when a gem_binary_path is provided" do
      let(:gem_binary) { "/usr/weird/bin/gem" }

      it "uses the AlternateGemEnvironment implementation when a gem_binary_path is provided" do
        expect(provider.gem_env.gem_binary_location).to eq(gem_binary)
      end

      context "when you try to use a hash of install options" do
        let(:options) { { fail: :burger } }

        it "smites you" do
          expect { provider }.to raise_error(ArgumentError)
        end
      end
    end

    context "when in omnibus opscode" do
      let(:bindir) { "/opt/opscode/embedded/bin" }

      it "recognizes opscode as omnibus" do
        expect(provider.is_omnibus?).to be true
      end
    end

    context "when in omnibus chefdk" do
      let(:bindir) { "/opt/chefdk/embedded/bin" }

      it "recognizes chefdk as omnibus" do
        expect(provider.is_omnibus?).to be true
      end
    end

    context "when in omnibus chef" do
      let(:bindir) { "/opt/chef/embedded/bin" }

      it "recognizes chef as omnibus" do
        expect(provider.is_omnibus?).to be true
      end

      it "searches for a gem binary when running on Omnibus on Unix" do
        platform_mock :unix do
          allow(ENV).to receive(:[]).with("PATH").and_return("/usr/bin:/usr/sbin:/opt/chef/embedded/bin")
          allow(ENV).to receive(:[]).with("PATHEXT").and_return(nil)
          allow(File).to receive(:executable?).with("/usr/bin/gem").and_return(false)
          allow(File).to receive(:executable?).with("/usr/sbin/gem").and_return(true)
          allow(File).to receive(:executable?).with("/opt/chef/embedded/bin/gem").and_return(true) # should not get here
          expect(provider.gem_env.gem_binary_location).to eq("/usr/sbin/gem")
        end
      end

      context "when on Windows" do
        let(:bindir) { "d:/opscode/chef/embedded/bin" }

        it "searches for a gem binary when running on Omnibus on Windows" do
          platform_mock :windows do
            allow(ENV).to receive(:[]).with("PATH").and_return('C:\windows\system32;C:\windows;C:\Ruby186\bin')
            allow(ENV).to receive(:[]).with("PATHEXT").and_return(nil)
            allow(File).to receive(:executable?).with('C:\\windows\\system32/gem').and_return(false)
            allow(File).to receive(:executable?).with('C:\\windows/gem').and_return(false)
            allow(File).to receive(:executable?).with('C:\\Ruby186\\bin/gem').and_return(true)
            allow(File).to receive(:executable?).with('d:\\opscode\\chef\\bin/gem').and_return(false) # should not get here
            allow(File).to receive(:executable?).with('d:\\opscode\\chef\\bin/gem').and_return(false) # should not get here
            allow(File).to receive(:executable?).with("d:/opscode/chef/embedded/bin/gem").and_return(false) # should not get here
            expect(provider.gem_env.gem_binary_location).to eq('C:\Ruby186\bin/gem')
          end
        end
      end
    end

    it "converts the new resource into a gem dependency" do
      expect(provider.gem_dependency).to eq(gem_dep)
    end

    context "when the new resource is not the current version" do
      let(:target_version) { "~> 9000.0.2" }

      it "converts the new resource into a gem dependency" do
        expect(provider.gem_dependency).to eq(gem_dep)
      end
    end

    describe "when determining the currently installed version" do
      before do
        provider.load_current_resource
      end

      it "sets the current version to the version specified by the new resource if that version is installed" do
        expect(provider.current_resource.version).to eq(current_version)
      end

      context "if the requested version is not installed" do
        let(:target_version) { "9000.0.2" }

        it "sets the current version to the highest installed version if the requested version is not installed" do
          expect(provider.current_resource.version).to eq(current_version)
        end
      end

      context "if the package is not currently installed" do
        let(:gem_name) { "no-such-gem-should-exist-with-this-name" }

        it "leaves the current version at nil" do
          expect(provider.current_resource.version).to be_nil
        end
      end

    end

    describe "when determining the candidate version to install" do
      before do
        provider.load_current_resource
      end

      context "when the current version is the target version" do
        it "does not query for available versions" do
          # NOTE: odd use case -- we've equality pinned a version, but are calling :upgrade
          expect(provider.gem_env).not_to receive(:candidate_version_from_remote)
          expect(provider.gem_env).not_to receive(:install)
          provider.run_action(:upgrade)
          expect(new_resource).not_to be_updated_by_last_action
        end
      end

      context "when the current version satisfies the target version requirement" do
        let(:target_version) { ">= 0" }

        it "does not query for available versions on install" do
          expect(provider.gem_env).not_to receive(:candidate_version_from_remote)
          expect(provider.gem_env).not_to receive(:install)
          provider.run_action(:install)
          expect(new_resource).not_to be_updated_by_last_action
        end

        it "queries for available versions on upgrade" do
          expect(provider.gem_env).to receive(:candidate_version_from_remote)
            .and_return(Gem::Version.new("9000.0.2"))
          expect(provider.gem_env).to receive(:install)
          provider.run_action(:upgrade)
          expect(new_resource).to be_updated_by_last_action
        end
      end

      context "when the source is from the rubygems_url" do
        it "determines the candidate version by querying the remote gem servers" do
          Chef::Config[:rubygems_url] = "https://mirror1/"
          expect(provider.gem_env).to receive(:candidate_version_from_remote)
            .with(gem_dep, "https://mirror1/")
            .and_return(Gem::Version.new(target_version))
          expect(provider.candidate_version).to eq(target_version)
        end
      end

      context "when the requested source is a remote server" do
        let(:source) { "http://mygems.example.com" }

        it "determines the candidate version by querying the remote gem servers" do
          expect(provider.gem_env).to receive(:candidate_version_from_remote)
            .with(gem_dep, source)
            .and_return(Gem::Version.new(target_version))
          expect(provider.candidate_version).to eq(target_version)
        end

        it "overwrites the config variable" do
          new_resource.include_default_source false
          Chef::Config[:rubygems_url] = "https://overridden"
          expect(provider.gem_env).to receive(:candidate_version_from_remote)
            .with(gem_dep, source)
            .and_return(Gem::Version.new(target_version))
          expect(provider.candidate_version).to eq(target_version)
        end
      end

      context "when the requested source is an array" do
        let(:source) { [ "https://mirror1", "https://mirror2" ] }

        it "determines the candidate version by querying the remote gem servers" do
          expect(provider.gem_env).to receive(:candidate_version_from_remote)
            .with(gem_dep, *source)
            .and_return(Gem::Version.new(target_version))
          expect(provider.candidate_version).to eq(target_version)
        end

        it "overwrites the config variable" do
          new_resource.include_default_source false
          Chef::Config[:rubygems_url] = "https://overridden"
          expect(provider.gem_env).to receive(:candidate_version_from_remote)
            .with(gem_dep, *source)
            .and_return(Gem::Version.new(target_version))
          expect(provider.candidate_version).to eq(target_version)
        end
      end

      context "when the requested source is a file" do
        let(:gem_name) { "chef-integration-test" }
        let(:source) { CHEF_SPEC_DATA + "/gems/chef-integration-test-0.1.0.gem" }
        let(:target_version) { ">= 0" }

        it "parses the gem's specification" do
          expect(provider.candidate_version).to eq("0.1.0")
        end
      end
    end

    describe "when installing a gem" do
      let(:target_version) { "9000.0.2" }
      let(:current_version) { nil }
      let(:candidate_version) { "9000.0.2" }
      let(:current_resource) do
        current_resource = Chef::Resource::GemPackage.new(gem_name)
        current_resource.version(current_version)
        current_resource
      end

      let(:version) { Gem::Version.new(candidate_version) }

      before do
        expected_source = [ source ]
        expected_source << "https://rubygems.org" if provider.include_default_source?
        allow(provider.gem_env).to receive(:candidate_version_from_remote).with(gem_dep, *expected_source.flatten.compact).and_return(version)
      end

      describe "in the current gem environment" do
        it "installs the gem via the gems api when no explicit options are used" do
          expect(provider.gem_env).to receive(:install).with(gem_dep, sources: [ "https://rubygems.org" ])
          provider.run_action(:install)
          expect(new_resource).to be_updated_by_last_action
        end

        context "when a remote source is provided" do
          let(:source) { "http://gems.example.org" }

          it "installs the gem via the gems api" do
            expect(provider.gem_env).to receive(:install).with(gem_dep, sources: [source])
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        context "when source is a path" do
          let(:source) { CHEF_SPEC_DATA + "/gems/chef-integration-test-0.1.0.gem" }

          it "installs the gem from file via the gems api" do
            expect(provider.gem_env).to receive(:install).with(source)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        context "when the gem name is a file path and source is nil" do
          let(:gem_name) { CHEF_SPEC_DATA + "/gems/chef-integration-test-0.1.0.gem" }

          it "installs the gem from file via the gems api" do
            expect(new_resource.source).to eq(gem_name)
            expect(provider.gem_env).to receive(:install).with(gem_name)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        # this catches 'gem_package "foo"' when "./foo" is a file in the cwd, and instead of installing './foo' it fetches the remote gem
        it "installs the gem via the gems api, when the package has no file separator characters in it, but a matching file exists in cwd" do
          allow(::File).to receive(:exist?).and_return(true)
          new_resource.package_name("rspec-core")
          expect(provider.gem_env).to receive(:install).with(gem_dep, sources: [ "https://rubygems.org" ])
          provider.run_action(:install)
          expect(new_resource).to be_updated_by_last_action
        end

        context "when options are provided as a String" do
          let(:options) { "-i /alt/install/location" }

          it "installs the gem by shelling out when options are provided as a String" do
            expected = "gem install rspec-core -q --no-document -v \"#{target_version}\" --source=https://rubygems.org #{options}"
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end

          it "unmockening needs_nodocument?" do
            expected = "gem install rspec-core -q --no-document -v \"#{target_version}\" --source=https://rubygems.org #{options}"
            expect(provider).to receive(:needs_nodocument?).and_call_original
            stub_const("Gem::VERSION", "3.0.0")
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end

          it "when the rubygems_version is old it uses the old flags" do
            expected = "gem install rspec-core -q --no-rdoc --no-ri -v \"#{target_version}\" --source=https://rubygems.org #{options}"
            expect(provider).to receive(:needs_nodocument?).and_call_original
            stub_const("Gem::VERSION", "2.8.0")
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        context "when the Chef::Config[:rubygems_url] option is provided" do
          let(:gem_binary) { "/foo/bar" }

          it "installs the gem" do
            Chef::Config[:rubygems_url] = "https://mirror1"
            expect(provider.gem_env).to receive(:candidate_version_from_remote).with(gem_dep, "https://mirror1").and_return(version)
            expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --clear-sources --source=https://mirror1"
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        context "when another source and binary are provided" do
          let(:source) { "http://mirror.ops.rhcloud.com/mirror/ruby" }
          let(:gem_binary) { "/foo/bar" }

          it "installs the gem" do
            expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --clear-sources --source=#{source}"
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end

          context "with include_default_source true" do
            let(:include_default_source) { true }

            it "ignores the Chef::Config setting" do
              expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --clear-sources --source=#{source} --source=https://rubygems.org"
              expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
              provider.run_action(:install)
              expect(new_resource).to be_updated_by_last_action
            end
          end

          context "with include_default_source false" do
            let(:include_default_source) { false }

            it "ignores the Chef::Config setting" do
              Chef::Config[:rubygems_url] = "https://ignored"
              expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --clear-sources --source=#{source}"
              expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
              provider.run_action(:install)
              expect(new_resource).to be_updated_by_last_action
            end
          end
        end

        context "when the source is an array" do
          let(:source) { [ "https://mirror1" , "https://mirror2" ] }
          let(:gem_binary) { "/foo/bar" }

          it "installs the gem with an array as an added source" do
            expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --clear-sources --source=https://mirror1 --source=https://mirror2"
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end

          context "with include_default_source true" do
            let(:include_default_source) { true }

            it "installs the gem with rubygems as a source" do
              expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --clear-sources --source=https://mirror1 --source=https://mirror2 --source=https://rubygems.org"
              expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
              provider.run_action(:install)
              expect(new_resource).to be_updated_by_last_action
            end
          end

          context "with include_default_source false" do
            let(:include_default_source) { false }

            it "ignores the Chef::Config setting" do
              Chef::Config[:rubygems_url] = "https://ignored"
              expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --clear-sources --source=https://mirror1 --source=https://mirror2"
              expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
              provider.run_action(:install)
              expect(new_resource).to be_updated_by_last_action
            end
          end
        end

        context "when clear_sources is set true and an explicit source is specified" do
          let(:gem_binary) { "/foo/bar" }
          let(:source) { "http://mirror.ops.rhcloud.com/mirror/ruby" }

          it "installs the gem" do
            new_resource.clear_sources(true)
            expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --clear-sources --source=#{source}"
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        context "when clear_sources is set false and an explicit source is specified" do
          let(:gem_binary) { "/foo/bar" }
          let(:source) { "http://mirror.ops.rhcloud.com/mirror/ruby" }

          it "installs the gem" do
            new_resource.clear_sources(false)
            expected = "#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --source=#{source}"
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        context "when no version is given" do
          let(:target_version) { nil }
          let(:options) { "-i /alt/install/location" }

          it "installs the gem by shelling out when options are provided but no version is given" do
            expected = "gem install rspec-core -q --no-document -v \"#{candidate_version}\" --source=https://rubygems.org #{options}"
            expect(provider).to receive(:shell_out_compacted!).with(expected, env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        context "when options are given as a Hash" do
          let(:options) { { install_dir: "/alt/install/location" } }

          it "installs the gem via the gems api when options are given as a Hash" do
            expect(provider.gem_env).to receive(:install).with(gem_dep, { sources: [ "https://rubygems.org" ] }.merge(options))
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        describe "at a specific version" do
          let(:target_version) { "9000.0.2" }

          it "installs the gem via the gems api" do
            expect(provider.gem_env).to receive(:install).with(gem_dep, sources: [ "https://rubygems.org" ] )
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        describe "at version specified with comparison operator" do
          context "if current version satisfies requested version" do
            let(:target_version) { ">=2.3.0" }
            let(:current_version) { "2.3.3" }

            it "skips the install" do
              expect(provider.gem_env).not_to receive(:install)
              provider.run_action(:install)
            end

            it "performs the upgrade" do
              expect(provider.gem_env).to receive(:install)
              provider.run_action(:upgrade)
            end
          end

          context "if the fuzzy operator is used" do
            let(:target_version) { "~>2.3.0" }
            let(:current_version) { "2.3.3" }

            it "it matches an existing gem" do
              expect(provider.gem_env).not_to receive(:install)
              provider.run_action(:install)
            end

            it "it upgrades an existing gem" do
              expect(provider.gem_env).to receive(:install)
              provider.run_action(:upgrade)
            end
          end
        end
      end

      describe "in an alternate gem environment" do
        let(:gem_binary) { "/usr/weird/bin/gem" }

        it "installs the gem by shelling out to gem install" do
          expect(provider).to receive(:shell_out_compacted!).with("#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --source=https://rubygems.org", env: nil, timeout: 900)
          provider.run_action(:install)
          expect(new_resource).to be_updated_by_last_action
        end

        it "unmockening needs_nodocument?" do
          expect(provider).to receive(:needs_nodocument?).and_call_original
          expect(provider.gem_env).to receive(:shell_out!).with("#{gem_binary} --version").and_return(instance_double(Mixlib::ShellOut, stdout: "3.0.0\n"))
          expect(provider).to receive(:shell_out_compacted!).with("#{gem_binary} install rspec-core -q --no-document -v \"#{target_version}\" --source=https://rubygems.org", env: nil, timeout: 900)
          provider.run_action(:install)
          expect(new_resource).to be_updated_by_last_action
        end

        it "when the rubygems_version is old it uses the old flags" do
          expect(provider).to receive(:needs_nodocument?).and_call_original
          expect(provider.gem_env).to receive(:shell_out!).with("#{gem_binary} --version").and_return(instance_double(Mixlib::ShellOut, stdout: "2.8.0\n"))
          expect(provider).to receive(:shell_out_compacted!).with("#{gem_binary} install rspec-core -q --no-rdoc --no-ri -v \"#{target_version}\" --source=https://rubygems.org", env: nil, timeout: 900)
          provider.run_action(:install)
          expect(new_resource).to be_updated_by_last_action
        end

        context "when source is a path" do
          let(:source) { CHEF_SPEC_DATA + "/gems/chef-integration-test-0.1.0.gem" }
          let(:target_version) { ">= 0" }

          it "installs the gem by shelling out to gem install" do
            expect(provider).to receive(:shell_out_compacted!).with("#{gem_binary} install #{source} -q --no-document -v \"#{target_version}\"", env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end

        context "when the package is a path and source is nil" do
          let(:gem_name) { CHEF_SPEC_DATA + "/gems/chef-integration-test-0.1.0.gem" }
          let(:target_version) { ">= 0" }

          it "installs the gem from file by shelling out to gem install when the package is a path and the source is nil" do
            expect(new_resource.source).to eq(gem_name)
            expect(provider).to receive(:shell_out_compacted!).with("#{gem_binary} install #{gem_name} -q --no-document -v \"#{target_version}\"", env: nil, timeout: 900)
            provider.run_action(:install)
            expect(new_resource).to be_updated_by_last_action
          end
        end
      end

    end

    describe "when uninstalling a gem" do
      let(:gem_name) { "rspec" }
      let(:current_version) { "1.2.3" }
      let(:target_version) { nil }

      let(:current_resource) do
        current_resource = Chef::Resource::GemPackage.new(gem_name)
        current_resource.version(current_version)
        current_resource
      end

      describe "in the current gem environment" do
        it "uninstalls via the api when no explicit options are used" do
          # pre-reqs for action_remove to actually remove the package:
          expect(provider.new_resource.version).to be_nil
          expect(provider.current_resource.version).not_to be_nil
          # the behavior we're testing:
          expect(provider.gem_env).to receive(:uninstall).with("rspec", nil)
          provider.action_remove
        end

        context "when options are given as a Hash" do
          let(:options) { { install_dir: "/alt/install/location" } }

          it "uninstalls via the api" do
            # pre-reqs for action_remove to actually remove the package:
            expect(provider.new_resource.version).to be_nil
            expect(provider.current_resource.version).not_to be_nil
            # the behavior we're testing:
            expect(provider.gem_env).to receive(:uninstall).with("rspec", nil, options)
            provider.action_remove
          end
        end

        context "when options are given as a String" do
          let(:options) { "-i /alt/install/location" }

          it "uninstalls via the gem command" do
            expect(provider).to receive(:shell_out_compacted!).with("gem uninstall rspec -q -x -I -a #{options}", env: nil, timeout: 900)
            provider.action_remove
          end
        end

        context "when a version is provided" do
          let(:target_version) { "1.2.3" }

          it "uninstalls a specific version of a gem" do
            expect(provider.gem_env).to receive(:uninstall).with("rspec", "1.2.3")
            provider.action_remove
          end
        end
      end

      describe "in an alternate gem environment" do
        let(:gem_binary) { "/usr/weird/bin/gem" }

        it "uninstalls via the gem command" do
          expect(provider).to receive(:shell_out_compacted!).with("#{gem_binary} uninstall rspec -q -x -I -a", env: nil, timeout: 900)
          provider.action_remove
        end
      end
    end
  end
end

describe Chef::Provider::Package::Rubygems, "clear_sources?" do
  let(:new_resource) do
    Chef::Resource::GemPackage.new("foo")
  end

  let(:provider) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    Chef::Provider::Package::Rubygems.new(new_resource, run_context)
  end

  it "is false when clear_sources is unset" do
    expect(provider.clear_sources?).to be false
  end

  it "is false when clear_sources is set false" do
    new_resource.clear_sources(false)
    expect(provider.clear_sources?).to be false
  end

  it "is true when clear_sources is set true" do
    new_resource.clear_sources(true)
    expect(provider.clear_sources?).to be true
  end

  context "when a source is set" do
    before do
      new_resource.source("http://mirror.ops.rhcloud.com/mirror/ruby")
    end

    it "is true when clear_sources is unset" do
      expect(provider.clear_sources?).to be true
    end

    it "is false when clear_sources is set false" do
      new_resource.clear_sources(false)
      expect(provider.clear_sources?).to be false
    end

    it "is true when clear_sources is set true" do
      new_resource.clear_sources(true)
      expect(provider.clear_sources?).to be true
    end
  end

  context "when Chef::Config[:rubygems_url] is set" do
    before do
      Chef::Config.rubygems_url = "https://example.com/"
    end

    it "is true when clear_sources is unset" do
      expect(provider.clear_sources?).to be true
    end

    it "is false when clear_sources is set false" do
      new_resource.clear_sources(false)
      expect(provider.clear_sources?).to be false
    end

    it "is true when clear_sources is set true" do
      new_resource.clear_sources(true)
      expect(provider.clear_sources?).to be true
    end
  end
end

describe Chef::Provider::Package::Rubygems, "include_default_source?" do
  let(:new_resource) do
    Chef::Resource::GemPackage.new("foo")
  end

  let(:provider) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    Chef::Provider::Package::Rubygems.new(new_resource, run_context)
  end

  it "is true when include_default_source is unset" do
    expect(provider.include_default_source?).to be true
  end

  it "is false when include_default_source is set false" do
    new_resource.include_default_source(false)
    expect(provider.include_default_source?).to be false
  end

  it "is true when include_default_source is set true" do
    new_resource.include_default_source(true)
    expect(provider.include_default_source?).to be true
  end

  context "when a source is set" do
    before do
      new_resource.source("http://mirror.ops.rhcloud.com/mirror/ruby")
    end

    it "is false when include_default_source is unset" do
      expect(provider.include_default_source?).to be false
    end

    it "is false when include_default_source is set false" do
      new_resource.include_default_source(false)
      expect(provider.include_default_source?).to be false
    end

    it "is true when include_default_source is set true" do
      new_resource.include_default_source(true)
      expect(provider.include_default_source?).to be true
    end
  end

  context "when Chef::Config[:rubygems_url] is set" do
    before do
      Chef::Config.rubygems_url = "https://example.com/"
    end

    it "is true when include_default_source is unset" do
      expect(provider.include_default_source?).to be true
    end

    it "is false when include_default_source is set false" do
      new_resource.include_default_source(false)
      expect(provider.include_default_source?).to be false
    end

    it "is true when include_default_source is set true" do
      new_resource.include_default_source(true)
      expect(provider.include_default_source?).to be true
    end
  end

  context "when clear_sources is set" do
    before do
      new_resource.clear_sources(true)
    end

    it "is false when include_default_source is unset" do
      expect(provider.include_default_source?).to be false
    end

    it "is false when include_default_source is set false" do
      new_resource.include_default_source(false)
      expect(provider.include_default_source?).to be false
    end

    it "is true when include_default_source is set true" do
      new_resource.include_default_source(true)
      expect(provider.include_default_source?).to be true
    end
  end
end
