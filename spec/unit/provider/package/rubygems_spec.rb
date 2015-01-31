#
# Author:: David Balatero (dbalatero@gmail.com)
#
# Copyright:: Copyright (c) 2009 David Balatero
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
require 'pp'

module GemspecBackcompatCreator
  def gemspec(name, version)
    if Gem::Specification.new.method(:initialize).arity == 0
      Gem::Specification.new { |s| s.name = name; s.version = version }
    else
      Gem::Specification.new(name, version)
    end
  end
end

require 'spec_helper'
require 'ostruct'

describe Chef::Provider::Package::Rubygems::CurrentGemEnvironment do
  include GemspecBackcompatCreator

  before do
    @gem_env = Chef::Provider::Package::Rubygems::CurrentGemEnvironment.new
  end

  it "determines the gem paths from the in memory rubygems" do
    expect(@gem_env.gem_paths).to eq(Gem.path)
  end

  it "determines the installed versions of gems from Gem.source_index" do
    gems = [gemspec('rspec-core', Gem::Version.new('1.2.9')), gemspec('rspec-core', Gem::Version.new('1.3.0'))]
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
      expect(Gem::Specification).to receive(:find_all_by_name).with('rspec-core', Gem::Dependency.new('rspec-core').requirement).and_return(gems)
    else
      expect(Gem.source_index).to receive(:search).with(Gem::Dependency.new('rspec-core', nil)).and_return(gems)
    end
    expect(@gem_env.installed_versions(Gem::Dependency.new('rspec-core', nil))).to eq(gems)
  end

  it "determines the installed versions of gems from the source index (part2: the unmockening)" do
    expected = ['rspec-core', Gem::Version.new(RSpec::Core::Version::STRING)]
    actual = @gem_env.installed_versions(Gem::Dependency.new('rspec-core', nil)).map { |spec| [spec.name, spec.version] }
    expect(actual).to include(expected)
  end

  it "yields to a block with an alternate source list set" do
    sources_in_block = nil
    normal_sources = Gem.sources
    begin
      @gem_env.with_gem_sources("http://gems.example.org") do
        sources_in_block = Gem.sources
        raise RuntimeError, "sources should be reset even in case of an error"
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
        raise RuntimeError, "sources should be reset even in case of an error"
      end
    rescue RuntimeError
    end
    expect(sources_in_block).to eq(normal_sources)
    expect(Gem.sources).to eq(normal_sources)
  end

  it "finds a matching gem candidate version" do
    dep = Gem::Dependency.new('rspec', '>= 0')
    dep_installer = Gem::DependencyInstaller.new
    allow(@gem_env).to receive(:dependency_installer).and_return(dep_installer)
    latest = [[gemspec("rspec", Gem::Version.new("1.3.0")), "https://rubygems.org/"]]
    expect(dep_installer).to receive(:find_gems_with_sources).with(dep).and_return(latest)
    expect(@gem_env.candidate_version_from_remote(Gem::Dependency.new('rspec', '>= 0'))).to eq(Gem::Version.new('1.3.0'))
  end

  it "finds a matching gem candidate version on rubygems 2.0.0+" do
    dep = Gem::Dependency.new('rspec', '>= 0')
    dep_installer = Gem::DependencyInstaller.new
    allow(@gem_env).to receive(:dependency_installer).and_return(dep_installer)
    best_gem = double("best gem match", :spec => gemspec("rspec", Gem::Version.new("1.3.0")), :source => "https://rubygems.org")
    available_set = double("Gem::AvailableSet test double")
    expect(available_set).to receive(:pick_best!)
    expect(available_set).to receive(:set).and_return([best_gem])
    expect(dep_installer).to receive(:find_gems_with_sources).with(dep).and_return(available_set)
    expect(@gem_env.candidate_version_from_remote(Gem::Dependency.new('rspec', '>= 0'))).to eq(Gem::Version.new('1.3.0'))
  end

  context "when rubygems was upgraded from 1.8->2.0" do
    # https://github.com/rubygems/rubygems/issues/404
    # tl;dr rubygems 1.8 and 2.0 can both be in the load path, which means that
    # require "rubygems/format" will load even though rubygems 2.0 doesn't have
    # that file.

    before do
      if defined?(Gem::Format)
        # tests are running under rubygems 1.8, or 2.0 upgraded from 1.8
        @remove_gem_format = false
      else
        Gem.const_set(:Format, Object.new)
        @remove_gem_format = true
      end
      allow(Gem::Package).to receive(:respond_to?).and_call_original
      allow(Gem::Package).to receive(:respond_to?).with(:open).and_return(false)
    end

    after do
      if @remove_gem_format
        Gem.send(:remove_const, :Format)
      end
    end

    it "finds a matching gem candidate version on rubygems 2.0+ with some rubygems 1.8 code loaded" do
      package = double("Gem::Package", :spec => "a gemspec from package")
      expect(Gem::Package).to receive(:new).with("/path/to/package.gem").and_return(package)
      expect(@gem_env.spec_from_file("/path/to/package.gem")).to eq("a gemspec from package")
    end

  end

  it "gives the candidate version as nil if none is found" do
    dep = Gem::Dependency.new('rspec', '>= 0')
    latest = []
    dep_installer = Gem::DependencyInstaller.new
    allow(@gem_env).to receive(:dependency_installer).and_return(dep_installer)
    expect(dep_installer).to receive(:find_gems_with_sources).with(dep).and_return(latest)
    expect(@gem_env.candidate_version_from_remote(Gem::Dependency.new('rspec', '>= 0'))).to be_nil
  end

  it "finds a matching candidate version from a .gem file when the path to the gem is supplied" do
    location = CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem'
    expect(@gem_env.candidate_version_from_file(Gem::Dependency.new('chef-integration-test', '>= 0'), location)).to eq(Gem::Version.new('0.1.0'))
    expect(@gem_env.candidate_version_from_file(Gem::Dependency.new('chef-integration-test', '>= 0.2.0'), location)).to be_nil
  end

  it "finds a matching gem from a specific gemserver when explicit sources are given" do
    dep = Gem::Dependency.new('rspec', '>= 0')
    latest = [[gemspec("rspec", Gem::Version.new("1.3.0")), "https://rubygems.org/"]]

    expect(@gem_env).to receive(:with_gem_sources).with('http://gems.example.com').and_yield
    dep_installer = Gem::DependencyInstaller.new
    allow(@gem_env).to receive(:dependency_installer).and_return(dep_installer)
    expect(dep_installer).to receive(:find_gems_with_sources).with(dep).and_return(latest)
    expect(@gem_env.candidate_version_from_remote(Gem::Dependency.new('rspec', '>=0'), 'http://gems.example.com')).to eq(Gem::Version.new('1.3.0'))
  end

  it "installs a gem with a hash of options for the dependency installer" do
    dep_installer = Gem::DependencyInstaller.new
    expect(@gem_env).to receive(:dependency_installer).with(:install_dir => '/foo/bar').and_return(dep_installer)
    expect(@gem_env).to receive(:with_gem_sources).with('http://gems.example.com').and_yield
    expect(dep_installer).to receive(:install).with(Gem::Dependency.new('rspec', '>= 0'))
    @gem_env.install(Gem::Dependency.new('rspec', '>= 0'), :install_dir => '/foo/bar', :sources => ['http://gems.example.com'])
  end

  it "builds an uninstaller for a gem with options set to avoid requiring user input" do
    # default options for uninstaller should be:
    # :ignore => true, :executables => true
    expect(Gem::Uninstaller).to receive(:new).with('rspec', :ignore => true, :executables => true)
    @gem_env.uninstaller('rspec')
  end

  it "uninstalls all versions of a gem" do
    uninstaller = double('gem uninstaller')
    expect(uninstaller).to receive(:uninstall)
    expect(@gem_env).to receive(:uninstaller).with('rspec', :all => true).and_return(uninstaller)
    @gem_env.uninstall('rspec')
  end

  it "uninstalls a specific version of a gem" do
    uninstaller = double('gem uninstaller')
    expect(uninstaller).to receive(:uninstall)
    expect(@gem_env).to receive(:uninstaller).with('rspec', :version => '1.2.3').and_return(uninstaller)
    @gem_env.uninstall('rspec', '1.2.3')
  end

end

describe Chef::Provider::Package::Rubygems::AlternateGemEnvironment do
  include GemspecBackcompatCreator

  before do
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.gempath_cache.clear
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache.clear
    @gem_env = Chef::Provider::Package::Rubygems::AlternateGemEnvironment.new('/usr/weird/bin/gem')
  end

  it "determines the gem paths from shelling out to gem env" do
    gem_env_output = ['/path/to/gems', '/another/path/to/gems'].join(File::PATH_SEPARATOR)
    shell_out_result = OpenStruct.new(:stdout => gem_env_output)
    expect(@gem_env).to receive(:shell_out!).with('/usr/weird/bin/gem env gempath').and_return(shell_out_result)
    expect(@gem_env.gem_paths).to eq(['/path/to/gems', '/another/path/to/gems'])
  end

  it "caches the gempaths by gem_binary" do
    gem_env_output = ['/path/to/gems', '/another/path/to/gems'].join(File::PATH_SEPARATOR)
    shell_out_result = OpenStruct.new(:stdout => gem_env_output)
    expect(@gem_env).to receive(:shell_out!).with('/usr/weird/bin/gem env gempath').and_return(shell_out_result)
    expected = ['/path/to/gems', '/another/path/to/gems']
    expect(@gem_env.gem_paths).to eq(['/path/to/gems', '/another/path/to/gems'])
    expect(Chef::Provider::Package::Rubygems::AlternateGemEnvironment.gempath_cache['/usr/weird/bin/gem']).to eq(expected)
  end

  it "uses the cached result for gem paths when available" do
    gem_env_output = ['/path/to/gems', '/another/path/to/gems'].join(File::PATH_SEPARATOR)
    shell_out_result = OpenStruct.new(:stdout => gem_env_output)
    expect(@gem_env).not_to receive(:shell_out!)
    expected = ['/path/to/gems', '/another/path/to/gems']
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.gempath_cache['/usr/weird/bin/gem']= expected
    expect(@gem_env.gem_paths).to eq(['/path/to/gems', '/another/path/to/gems'])
  end

  it "builds the gems source index from the gem paths" do
    allow(@gem_env).to receive(:gem_paths).and_return(['/path/to/gems', '/another/path/to/gems'])
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
      @gem_env.gem_specification
      expect(Gem::Specification.dirs).to eq([ '/path/to/gems/specifications', '/another/path/to/gems/specifications' ])
    else
      expect(Gem::SourceIndex).to receive(:from_gems_in).with('/path/to/gems/specifications', '/another/path/to/gems/specifications')
      @gem_env.gem_source_index
    end
  end

  it "determines the installed versions of gems from the source index" do
    gems = [gemspec('rspec', Gem::Version.new('1.2.9')), gemspec('rspec', Gem::Version.new('1.3.0'))]
    rspec_dep = Gem::Dependency.new('rspec', nil)
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
      allow(@gem_env).to receive(:gem_specification).and_return(Gem::Specification)
      expect(@gem_env.gem_specification).to receive(:find_all_by_name).with(rspec_dep.name, rspec_dep.requirement).and_return(gems)
    else
      allow(@gem_env).to receive(:gem_source_index).and_return(Gem.source_index)
      expect(@gem_env.gem_source_index).to receive(:search).with(rspec_dep).and_return(gems)
    end
    expect(@gem_env.installed_versions(Gem::Dependency.new('rspec', nil))).to eq(gems)
  end

  it "determines the installed versions of gems from the source index (part2: the unmockening)" do
    allow($stdout).to receive(:write)
    path_to_gem = if windows?
      `where gem`.split[1]
    else
      `which gem`.strip
    end
    pending("cant find your gem executable") if path_to_gem.empty?
    gem_env = Chef::Provider::Package::Rubygems::AlternateGemEnvironment.new(path_to_gem)
    expected = ['rspec-core', Gem::Version.new(RSpec::Core::Version::STRING)]
    actual = gem_env.installed_versions(Gem::Dependency.new('rspec-core', nil)).map { |s| [s.name, s.version] }
    expect(actual).to include(expected)
  end

  it "detects when the target gem environment is the jruby platform" do
    gem_env_out=<<-JRUBY_GEM_ENV
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
    expect(@gem_env).to receive(:shell_out!).with('/usr/weird/bin/gem env').and_return(double('jruby_gem_env', :stdout => gem_env_out))
    expected = ['ruby', Gem::Platform.new('universal-java-1.6')]
    expect(@gem_env.gem_platforms).to eq(expected)
    # it should also cache the result
    expect(Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache['/usr/weird/bin/gem']).to eq(expected)
  end

  it "uses the cached result for gem platforms if available" do
    expect(@gem_env).not_to receive(:shell_out!)
    expected = ['ruby', Gem::Platform.new('universal-java-1.6')]
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache['/usr/weird/bin/gem']= expected
    expect(@gem_env.gem_platforms).to eq(expected)
  end

  it "uses the current gem platforms when the target env is not jruby" do
    gem_env_out=<<-RBX_GEM_ENV
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
    expect(@gem_env).to receive(:shell_out!).with('/usr/weird/bin/gem env').and_return(double('rbx_gem_env', :stdout => gem_env_out))
    expect(@gem_env.gem_platforms).to eq(Gem.platforms)
    expect(Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache['/usr/weird/bin/gem']).to eq(Gem.platforms)
  end

  it "yields to a block while masquerading as a different gems platform" do
    original_platforms = Gem.platforms
    platforms_in_block = nil
    begin
      @gem_env.with_gem_platforms(['ruby', Gem::Platform.new('sparc64-java-1.7')]) do
        platforms_in_block = Gem.platforms
        raise "gem platforms should get set to the correct value even when an error occurs"
      end
    rescue RuntimeError
    end
    expect(platforms_in_block).to eq(['ruby', Gem::Platform.new('sparc64-java-1.7')])
    expect(Gem.platforms).to eq(original_platforms)
  end

end

describe Chef::Provider::Package::Rubygems do
  let(:target_version) { nil }

  before(:each) do
    @node = Chef::Node.new
    @new_resource = Chef::Resource::GemPackage.new("rspec-core")
    @spec_version = @new_resource.version(target_version)
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    # We choose detect omnibus via RbConfig::CONFIG['bindir'] in Chef::Provider::Package::Rubygems.new
    allow(RbConfig::CONFIG).to receive(:[]).with('bindir').and_return("/usr/bin/ruby")
    # Rubygems uses this interally
    allow(RbConfig::CONFIG).to receive(:[]).with('arch').and_call_original
    @provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
  end

  describe "when new_resource version is nil" do
    let(:target_version) { nil }

    it "target_version_already_installed? should return false so that we can search for candidates" do
      @provider.load_current_resource
      expect(@provider.target_version_already_installed?(@provider.current_resource.version, @new_resource.version)).to be_falsey
    end
  end

  describe "when new_resource version is current rspec version" do
    let(:target_version) { RSpec::Core::Version::STRING }

    it "triggers a gem configuration load so a later one will not stomp its config values" do
      # ugly, is there a better way?
      expect(Gem.instance_variable_get(:@configuration)).not_to be_nil
    end

    it "uses the CurrentGemEnvironment implementation when no gem_binary_path is provided" do
      expect(@provider.gem_env).to be_a_kind_of(Chef::Provider::Package::Rubygems::CurrentGemEnvironment)
    end

    it "uses the AlternateGemEnvironment implementation when a gem_binary_path is provided" do
      @new_resource.gem_binary('/usr/weird/bin/gem')
      provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
      expect(provider.gem_env.gem_binary_location).to eq('/usr/weird/bin/gem')
    end

    it "searches for a gem binary when running on Omnibus on Unix" do
      platform_mock :unix do
        allow(RbConfig::CONFIG).to receive(:[]).with('bindir').and_return("/opt/chef/embedded/bin")
        allow(ENV).to receive(:[]).with('PATH').and_return("/usr/bin:/usr/sbin:/opt/chef/embedded/bin")
        allow(File).to receive(:exists?).with('/usr/bin/gem').and_return(false)
        allow(File).to receive(:exists?).with('/usr/sbin/gem').and_return(true)
        allow(File).to receive(:exists?).with('/opt/chef/embedded/bin/gem').and_return(true) # should not get here
        provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
        expect(provider.gem_env.gem_binary_location).to eq('/usr/sbin/gem')
      end
    end

    it "searches for a gem binary when running on Omnibus on Windows" do
      platform_mock :windows do
        allow(RbConfig::CONFIG).to receive(:[]).with('bindir').and_return("d:/opscode/chef/embedded/bin")
        allow(ENV).to receive(:[]).with('PATH').and_return('C:\windows\system32;C:\windows;C:\Ruby186\bin;d:\opscode\chef\embedded\bin')
        allow(File).to receive(:exists?).with('C:\\windows\\system32\\gem').and_return(false)
        allow(File).to receive(:exists?).with('C:\\windows\\gem').and_return(false)
        allow(File).to receive(:exists?).with('C:\\Ruby186\\bin\\gem').and_return(true)
        allow(File).to receive(:exists?).with('d:\\opscode\\chef\\bin\\gem').and_return(false) # should not get here
        allow(File).to receive(:exists?).with('d:\\opscode\\chef\\embedded\\bin\\gem').and_return(false) # should not get here
        provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
        expect(provider.gem_env.gem_binary_location).to eq('C:\Ruby186\bin\gem')
      end
    end

    it "smites you when you try to use a hash of install options with an explicit gem binary" do
      @new_resource.gem_binary('/foo/bar')
      @new_resource.options(:fail => :burger)
      expect {Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)}.to raise_error(ArgumentError)
    end

    it "converts the new resource into a gem dependency" do
      expect(@provider.gem_dependency).to eq(Gem::Dependency.new('rspec-core', @spec_version))
      @new_resource.version('~> 1.2.0')
      expect(@provider.gem_dependency).to eq(Gem::Dependency.new('rspec-core', '~> 1.2.0'))
    end

    describe "when determining the currently installed version" do

      it "sets the current version to the version specified by the new resource if that version is installed" do
        @provider.load_current_resource
        expect(@provider.current_resource.version).to eq(@spec_version)
      end

      it "sets the current version to the highest installed version if the requested version is not installed" do
        @new_resource.version('9000.0.2')
        @provider.load_current_resource
        expect(@provider.current_resource.version).to eq(@spec_version)
      end

      it "leaves the current version at nil if the package is not installed" do
        @new_resource.package_name("no-such-gem-should-exist-with-this-name")
        @provider.load_current_resource
        expect(@provider.current_resource.version).to be_nil
      end

    end

    describe "when determining the candidate version to install" do

      it "does not query for available versions when the current version is the target version" do
        @provider.current_resource = @new_resource.dup
        expect(@provider.candidate_version).to be_nil
      end

      it "determines the candidate version by querying the remote gem servers" do
        @new_resource.source('http://mygems.example.com')
        @provider.load_current_resource
        @provider.current_resource.version('0.0.1')
        version = Gem::Version.new(@spec_version)
        expect(@provider.gem_env).to receive(:candidate_version_from_remote).
                          with(Gem::Dependency.new('rspec-core', @spec_version), "http://mygems.example.com").
                          and_return(version)
        expect(@provider.candidate_version).to eq(@spec_version)
      end

      it "parses the gem's specification if the requested source is a file" do
        @new_resource.package_name('chef-integration-test')
        @new_resource.source(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
        @new_resource.version('>= 0')
        @provider.load_current_resource
        expect(@provider.candidate_version).to eq('0.1.0')
      end

    end

    describe "when installing a gem" do
      before do
        @current_resource = Chef::Resource::GemPackage.new('rspec-core')
        @provider.current_resource = @current_resource
        @gem_dep = Gem::Dependency.new('rspec-core', @spec_version)
        allow(@provider).to receive(:load_current_resource)
      end

      describe "in the current gem environment" do
        it "installs the gem via the gems api when no explicit options are used" do
          expect(@provider.gem_env).to receive(:install).with(@gem_dep, :sources => nil)
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        it "installs the gem via the gems api when a remote source is provided" do
          @new_resource.source('http://gems.example.org')
          sources = ['http://gems.example.org']
          expect(@provider.gem_env).to receive(:install).with(@gem_dep, :sources => sources)
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        it "installs the gem from file via the gems api when no explicit options are used" do
          @new_resource.source(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
          expect(@provider.gem_env).to receive(:install).with(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        it "installs the gem from file via the gems api when the package is a path and the source is nil" do
          @new_resource = Chef::Resource::GemPackage.new(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
          @provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
          @provider.current_resource = @current_resource
          expect(@new_resource.source).to eq(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
          expect(@provider.gem_env).to receive(:install).with(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        # this catches 'gem_package "foo"' when "./foo" is a file in the cwd, and instead of installing './foo' it fetches the remote gem
        it "installs the gem via the gems api, when the package has no file separator characters in it, but a matching file exists in cwd" do
          allow(::File).to receive(:exists?).and_return(true)
          @new_resource.package_name('rspec-core')
          expect(@provider.gem_env).to receive(:install).with(@gem_dep, :sources => nil)
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        it "installs the gem by shelling out when options are provided as a String" do
          @new_resource.options('-i /alt/install/location')
          expected ="gem install rspec-core -q --no-rdoc --no-ri -v \"#{@spec_version}\" -i /alt/install/location"
          expect(@provider).to receive(:shell_out!).with(expected, :env => nil)
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        context "when no version is given" do
          let(:target_version) { nil }

          it "installs the gem by shelling out when options are provided but no version is given" do
            @new_resource.options('-i /alt/install/location')
            expected ="gem install rspec-core -q --no-rdoc --no-ri -v \"3.1.7\" -i /alt/install/location"
            expect(@provider).to receive(:shell_out!).with(expected, :env => nil)
            @provider.run_action(:install)
            expect(@new_resource).to be_updated_by_last_action
          end
        end

        it "installs the gem via the gems api when options are given as a Hash" do
          @new_resource.options(:install_dir => '/alt/install/location')
          expect(@provider.gem_env).to receive(:install).with(@gem_dep, :sources => nil, :install_dir => '/alt/install/location')
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        describe "at a specific version" do
          before do
            @gem_dep = Gem::Dependency.new('rspec-core', @spec_version)
          end

          it "installs the gem via the gems api" do
            expect(@provider.gem_env).to receive(:install).with(@gem_dep, :sources => nil)
            @provider.run_action(:install)
            expect(@new_resource).to be_updated_by_last_action
          end
        end
        describe "at version specified with comparison operator" do
          it "skips install if current version satisifies requested version" do
            @current_resource.version("2.3.3")
            @new_resource.version(">=2.3.0")

            expect(@provider.gem_env).not_to receive(:install)
            @provider.run_action(:install)
          end

          it "allows user to specify gem version with fuzzy operator" do
            @current_resource.version("2.3.3")
            @new_resource.version("~>2.3.0")

            expect(@provider.gem_env).not_to receive(:install)
            @provider.run_action(:install)
          end
        end
      end

      describe "in an alternate gem environment" do
        it "installs the gem by shelling out to gem install" do
          @new_resource.gem_binary('/usr/weird/bin/gem')
          expect(@provider).to receive(:shell_out!).with("/usr/weird/bin/gem install rspec-core -q --no-rdoc --no-ri -v \"#{@spec_version}\"", :env=>nil)
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        it "installs the gem from file by shelling out to gem install" do
          @new_resource.gem_binary('/usr/weird/bin/gem')
          @new_resource.source(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
          @new_resource.version('>= 0')
          expect(@provider).to receive(:shell_out!).with("/usr/weird/bin/gem install #{CHEF_SPEC_DATA}/gems/chef-integration-test-0.1.0.gem -q --no-rdoc --no-ri -v \">= 0\"", :env=>nil)
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end

        it "installs the gem from file by shelling out to gem install when the package is a path and the source is nil" do
          @new_resource = Chef::Resource::GemPackage.new(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
          @provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
          @provider.current_resource = @current_resource
          @new_resource.gem_binary('/usr/weird/bin/gem')
          @new_resource.version('>= 0')
          expect(@new_resource.source).to eq(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
          expect(@provider).to receive(:shell_out!).with("/usr/weird/bin/gem install #{CHEF_SPEC_DATA}/gems/chef-integration-test-0.1.0.gem -q --no-rdoc --no-ri -v \">= 0\"", :env=>nil)
          @provider.run_action(:install)
          expect(@new_resource).to be_updated_by_last_action
        end
      end

    end

    describe "when uninstalling a gem" do
      before do
        @new_resource = Chef::Resource::GemPackage.new("rspec")
        @current_resource = @new_resource.dup
        @current_resource.version('1.2.3')
        @provider.new_resource = @new_resource
        @provider.current_resource = @current_resource
      end

      describe "in the current gem environment" do
        it "uninstalls via the api when no explicit options are used" do
          # pre-reqs for action_remove to actually remove the package:
          expect(@provider.new_resource.version).to be_nil
          expect(@provider.current_resource.version).not_to be_nil
          # the behavior we're testing:
          expect(@provider.gem_env).to receive(:uninstall).with('rspec', nil)
          @provider.action_remove
        end

        it "uninstalls via the api when options are given as a Hash" do
          # pre-reqs for action_remove to actually remove the package:
          expect(@provider.new_resource.version).to be_nil
          expect(@provider.current_resource.version).not_to be_nil
          # the behavior we're testing:
          @new_resource.options(:install_dir => '/alt/install/location')
          expect(@provider.gem_env).to receive(:uninstall).with('rspec', nil, :install_dir => '/alt/install/location')
          @provider.action_remove
        end

        it "uninstalls via the gem command when options are given as a String" do
          @new_resource.options('-i /alt/install/location')
          expect(@provider).to receive(:shell_out!).with("gem uninstall rspec -q -x -I -a -i /alt/install/location", :env=>nil)
          @provider.action_remove
        end

        it "uninstalls a specific version of a gem when a version is provided" do
          @new_resource.version('1.2.3')
          expect(@provider.gem_env).to receive(:uninstall).with('rspec', '1.2.3')
          @provider.action_remove
        end
      end

      describe "in an alternate gem environment" do
        it "uninstalls via the gem command" do
          @new_resource.gem_binary('/usr/weird/bin/gem')
          expect(@provider).to receive(:shell_out!).with("/usr/weird/bin/gem uninstall rspec -q -x -I -a", :env=>nil)
          @provider.action_remove
        end
      end
    end
  end
end
