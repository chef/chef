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
    @gem_env.gem_paths.should == Gem.path
  end

  it "determines the installed versions of gems from Gem.source_index" do
    gems = [gemspec('rspec-core', Gem::Version.new('1.2.9')), gemspec('rspec-core', Gem::Version.new('1.3.0'))]
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
      Gem::Specification.should_receive(:find_all_by_name).with('rspec-core', Gem::Dependency.new('rspec-core').requirement).and_return(gems)
    else
      Gem.source_index.should_receive(:search).with(Gem::Dependency.new('rspec-core', nil)).and_return(gems)
    end
    @gem_env.installed_versions(Gem::Dependency.new('rspec-core', nil)).should == gems
  end

  it "determines the installed versions of gems from the source index (part2: the unmockening)" do
    expected = ['rspec-core', Gem::Version.new(RSpec::Core::Version::STRING)]
    actual = @gem_env.installed_versions(Gem::Dependency.new('rspec-core', nil)).map { |spec| [spec.name, spec.version] }
    actual.should include(expected)
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
    sources_in_block.should == %w{http://gems.example.org}
    Gem.sources.should == normal_sources
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
    sources_in_block.should == normal_sources
    Gem.sources.should == normal_sources
  end

  it "finds a matching gem candidate version" do
    dep = Gem::Dependency.new('rspec', '>= 0')
    dep_installer = Gem::DependencyInstaller.new
    @gem_env.stub!(:dependency_installer).and_return(dep_installer)
    latest = [[gemspec("rspec", Gem::Version.new("1.3.0")), "http://rubygems.org/"]]
    dep_installer.should_receive(:find_gems_with_sources).with(dep).and_return(latest)
    @gem_env.candidate_version_from_remote(Gem::Dependency.new('rspec', '>= 0')).should == Gem::Version.new('1.3.0')
  end

  it "finds a matching gem candidate version on rubygems 2.0.0+" do
    dep = Gem::Dependency.new('rspec', '>= 0')
    dep_installer = Gem::DependencyInstaller.new
    @gem_env.stub!(:dependency_installer).and_return(dep_installer)
    best_gem = mock("best gem match", :spec => gemspec("rspec", Gem::Version.new("1.3.0")), :source => "https://rubygems.org")
    available_set = mock("Gem::AvailableSet test double")
    available_set.should_receive(:pick_best!)
    available_set.should_receive(:set).and_return([best_gem])
    dep_installer.should_receive(:find_gems_with_sources).with(dep).and_return(available_set)
    @gem_env.candidate_version_from_remote(Gem::Dependency.new('rspec', '>= 0')).should == Gem::Version.new('1.3.0')
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
      Gem::Package.stub!(:respond_to?).with(:open).and_return(false)
    end

    after do
      if @remove_gem_format
        Gem.send(:remove_const, :Format)
      end
    end

    it "finds a matching gem candidate version on rubygems 2.0+ with some rubygems 1.8 code loaded" do
      package = mock("Gem::Package", :spec => "a gemspec from package")
      Gem::Package.should_receive(:new).with("/path/to/package.gem").and_return(package)
      @gem_env.spec_from_file("/path/to/package.gem").should == "a gemspec from package"
    end

  end

  it "gives the candidate version as nil if none is found" do
    dep = Gem::Dependency.new('rspec', '>= 0')
    latest = []
    dep_installer = Gem::DependencyInstaller.new
    @gem_env.stub!(:dependency_installer).and_return(dep_installer)
    dep_installer.should_receive(:find_gems_with_sources).with(dep).and_return(latest)
    @gem_env.candidate_version_from_remote(Gem::Dependency.new('rspec', '>= 0')).should be_nil
  end

  it "finds a matching candidate version from a .gem file when the path to the gem is supplied" do
    location = CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem'
    @gem_env.candidate_version_from_file(Gem::Dependency.new('chef-integration-test', '>= 0'), location).should == Gem::Version.new('0.1.0')
    @gem_env.candidate_version_from_file(Gem::Dependency.new('chef-integration-test', '>= 0.2.0'), location).should be_nil
  end

  it "finds a matching gem from a specific gemserver when explicit sources are given" do
    dep = Gem::Dependency.new('rspec', '>= 0')
    latest = [[gemspec("rspec", Gem::Version.new("1.3.0")), "http://rubygems.org/"]]

    @gem_env.should_receive(:with_gem_sources).with('http://gems.example.com').and_yield
    dep_installer = Gem::DependencyInstaller.new
    @gem_env.stub!(:dependency_installer).and_return(dep_installer)
    dep_installer.should_receive(:find_gems_with_sources).with(dep).and_return(latest)
    @gem_env.candidate_version_from_remote(Gem::Dependency.new('rspec', '>=0'), 'http://gems.example.com').should == Gem::Version.new('1.3.0')
  end

  it "installs a gem with a hash of options for the dependency installer" do
    dep_installer = Gem::DependencyInstaller.new
    @gem_env.should_receive(:dependency_installer).with(:install_dir => '/foo/bar').and_return(dep_installer)
    @gem_env.should_receive(:with_gem_sources).with('http://gems.example.com').and_yield
    dep_installer.should_receive(:install).with(Gem::Dependency.new('rspec', '>= 0'))
    @gem_env.install(Gem::Dependency.new('rspec', '>= 0'), :install_dir => '/foo/bar', :sources => ['http://gems.example.com'])
  end

  it "builds an uninstaller for a gem with options set to avoid requiring user input" do
    # default options for uninstaller should be:
    # :ignore => true, :executables => true
    Gem::Uninstaller.should_receive(:new).with('rspec', :ignore => true, :executables => true)
    @gem_env.uninstaller('rspec')
  end

  it "uninstalls all versions of a gem" do
    uninstaller = mock('gem uninstaller')
    uninstaller.should_receive(:uninstall)
    @gem_env.should_receive(:uninstaller).with('rspec', :all => true).and_return(uninstaller)
    @gem_env.uninstall('rspec')
  end

  it "uninstalls a specific version of a gem" do
    uninstaller = mock('gem uninstaller')
    uninstaller.should_receive(:uninstall)
    @gem_env.should_receive(:uninstaller).with('rspec', :version => '1.2.3').and_return(uninstaller)
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
    @gem_env.should_receive(:shell_out!).with('/usr/weird/bin/gem env gempath').and_return(shell_out_result)
    @gem_env.gem_paths.should == ['/path/to/gems', '/another/path/to/gems']
  end

  it "caches the gempaths by gem_binary" do
    gem_env_output = ['/path/to/gems', '/another/path/to/gems'].join(File::PATH_SEPARATOR)
    shell_out_result = OpenStruct.new(:stdout => gem_env_output)
    @gem_env.should_receive(:shell_out!).with('/usr/weird/bin/gem env gempath').and_return(shell_out_result)
    expected = ['/path/to/gems', '/another/path/to/gems']
    @gem_env.gem_paths.should == ['/path/to/gems', '/another/path/to/gems']
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.gempath_cache['/usr/weird/bin/gem'].should == expected
  end

  it "uses the cached result for gem paths when available" do
    gem_env_output = ['/path/to/gems', '/another/path/to/gems'].join(File::PATH_SEPARATOR)
    shell_out_result = OpenStruct.new(:stdout => gem_env_output)
    @gem_env.should_not_receive(:shell_out!)
    expected = ['/path/to/gems', '/another/path/to/gems']
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.gempath_cache['/usr/weird/bin/gem']= expected
    @gem_env.gem_paths.should == ['/path/to/gems', '/another/path/to/gems']
  end

  it "builds the gems source index from the gem paths" do
    @gem_env.stub!(:gem_paths).and_return(['/path/to/gems', '/another/path/to/gems'])
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
      @gem_env.gem_specification
      Gem::Specification.dirs.should == [ '/path/to/gems/specifications', '/another/path/to/gems/specifications' ]
    else
      Gem::SourceIndex.should_receive(:from_gems_in).with('/path/to/gems/specifications', '/another/path/to/gems/specifications')
      @gem_env.gem_source_index
    end
  end

  it "determines the installed versions of gems from the source index" do
    gems = [gemspec('rspec', Gem::Version.new('1.2.9')), gemspec('rspec', Gem::Version.new('1.3.0'))]
    rspec_dep = Gem::Dependency.new('rspec', nil)
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
      @gem_env.stub!(:gem_specification).and_return(Gem::Specification)
      @gem_env.gem_specification.should_receive(:find_all_by_name).with(rspec_dep.name, rspec_dep.requirement).and_return(gems)
    else
      @gem_env.stub!(:gem_source_index).and_return(Gem.source_index)
      @gem_env.gem_source_index.should_receive(:search).with(rspec_dep).and_return(gems)
    end
    @gem_env.installed_versions(Gem::Dependency.new('rspec', nil)).should == gems
  end

  it "determines the installed versions of gems from the source index (part2: the unmockening)" do
    $stdout.stub!(:write)
    path_to_gem = if windows?
      `where gem`.split[-1]
    else
      `which gem`.strip
    end
    pending("cant find your gem executable") if path_to_gem.empty?
    gem_env = Chef::Provider::Package::Rubygems::AlternateGemEnvironment.new(path_to_gem)
    expected = ['rspec-core', Gem::Version.new(RSpec::Core::Version::STRING)]
    actual = gem_env.installed_versions(Gem::Dependency.new('rspec-core', nil)).map { |s| [s.name, s.version] }
    actual.should include(expected)
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
     - :sources => ["http://rubygems.org/", "http://gems.github.com/"]
  - REMOTE SOURCES:
     - http://rubygems.org/
     - http://gems.github.com/
JRUBY_GEM_ENV
    @gem_env.should_receive(:shell_out!).with('/usr/weird/bin/gem env').and_return(mock('jruby_gem_env', :stdout => gem_env_out))
    expected = ['ruby', Gem::Platform.new('universal-java-1.6')]
    @gem_env.gem_platforms.should == expected
    # it should also cache the result
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache['/usr/weird/bin/gem'].should == expected
  end

  it "uses the cached result for gem platforms if available" do
    @gem_env.should_not_receive(:shell_out!)
    expected = ['ruby', Gem::Platform.new('universal-java-1.6')]
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache['/usr/weird/bin/gem']= expected
    @gem_env.gem_platforms.should == expected
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
     - :sources => ["http://rubygems.org/", "http://gems.github.com/"]
     - "gem" => "--no-rdoc --no-ri"
  - REMOTE SOURCES:
     - http://rubygems.org/
     - http://gems.github.com/
RBX_GEM_ENV
    @gem_env.should_receive(:shell_out!).with('/usr/weird/bin/gem env').and_return(mock('rbx_gem_env', :stdout => gem_env_out))
    @gem_env.gem_platforms.should == Gem.platforms
    Chef::Provider::Package::Rubygems::AlternateGemEnvironment.platform_cache['/usr/weird/bin/gem'].should == Gem.platforms
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
    platforms_in_block.should == ['ruby', Gem::Platform.new('sparc64-java-1.7')]
    Gem.platforms.should == original_platforms
  end

end

describe Chef::Provider::Package::Rubygems do
  before(:each) do
    @node = Chef::Node.new
    @new_resource = Chef::Resource::GemPackage.new("rspec-core")
    @spec_version = @new_resource.version RSpec::Core::Version::STRING
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    # We choose detect omnibus via RbConfig::CONFIG['bindir'] in Chef::Provider::Package::Rubygems.new
    RbConfig::CONFIG.stub!(:[]).with('bindir').and_return("/usr/bin/ruby")
    @provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
  end

  it "triggers a gem configuration load so a later one will not stomp its config values" do
    # ugly, is there a better way?
    Gem.instance_variable_get(:@configuration).should_not be_nil
  end

  it "uses the CurrentGemEnvironment implementation when no gem_binary_path is provided" do
    @provider.gem_env.should be_a_kind_of(Chef::Provider::Package::Rubygems::CurrentGemEnvironment)
  end

  it "uses the AlternateGemEnvironment implementation when a gem_binary_path is provided" do
    @new_resource.gem_binary('/usr/weird/bin/gem')
    provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
    provider.gem_env.gem_binary_location.should == '/usr/weird/bin/gem'
  end

  it "searches for a gem binary when running on Omnibus on Unix" do
    platform_mock :unix do
      RbConfig::CONFIG.stub!(:[]).with('bindir').and_return("/opt/chef/embedded/bin")
      ENV.stub!(:[]).with('PATH').and_return("/usr/bin:/usr/sbin:/opt/chef/embedded/bin")
      File.stub!(:exists?).with('/usr/bin/gem').and_return(false)
      File.stub!(:exists?).with('/usr/sbin/gem').and_return(true)
      File.stub!(:exists?).with('/opt/chef/embedded/bin/gem').and_return(true) # should not get here
      provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
      provider.gem_env.gem_binary_location.should == '/usr/sbin/gem'
    end
  end

  it "searches for a gem binary when running on Omnibus on Windows" do
    platform_mock :windows do
      RbConfig::CONFIG.stub!(:[]).with('bindir').and_return("d:/opscode/chef/embedded/bin")
      ENV.stub!(:[]).with('PATH').and_return('C:\windows\system32;C:\windows;C:\Ruby186\bin;d:\opscode\chef\embedded\bin')
      File.stub!(:exists?).with('C:\\windows\\system32\\gem').and_return(false)
      File.stub!(:exists?).with('C:\\windows\\gem').and_return(false)
      File.stub!(:exists?).with('C:\\Ruby186\\bin\\gem').and_return(true)
      File.stub!(:exists?).with('d:\\opscode\\chef\\bin\\gem').and_return(false) # should not get here
      File.stub!(:exists?).with('d:\\opscode\\chef\\embedded\\bin\\gem').and_return(false) # should not get here
      provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
      provider.gem_env.gem_binary_location.should == 'C:\Ruby186\bin\gem'
    end
  end

  it "smites you when you try to use a hash of install options with an explicit gem binary" do
    @new_resource.gem_binary('/foo/bar')
    @new_resource.options(:fail => :burger)
    lambda {Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)}.should raise_error(ArgumentError)
  end

  it "converts the new resource into a gem dependency" do
    @provider.gem_dependency.should == Gem::Dependency.new('rspec-core', @spec_version)
    @new_resource.version('~> 1.2.0')
    @provider.gem_dependency.should == Gem::Dependency.new('rspec-core', '~> 1.2.0')
  end

  describe "when determining the currently installed version" do

    it "sets the current version to the version specified by the new resource if that version is installed" do
      @provider.load_current_resource
      @provider.current_resource.version.should == @spec_version
    end

    it "sets the current version to the highest installed version if the requested version is not installed" do
      @new_resource.version('9000.0.2')
      @provider.load_current_resource
      @provider.current_resource.version.should == @spec_version
    end

    it "leaves the current version at nil if the package is not installed" do
      @new_resource.package_name("no-such-gem-should-exist-with-this-name")
      @provider.load_current_resource
      @provider.current_resource.version.should be_nil
    end

  end

  describe "when determining the candidate version to install" do

    it "does not query for available versions when the current version is the target version" do
      @provider.current_resource = @new_resource.dup
      @provider.candidate_version.should be_nil
    end

    it "determines the candidate version by querying the remote gem servers" do
      @new_resource.source('http://mygems.example.com')
      version = Gem::Version.new(@spec_version)
      @provider.gem_env.should_receive(:candidate_version_from_remote).
                        with(Gem::Dependency.new('rspec-core', @spec_version), "http://mygems.example.com").
                        and_return(version)
      @provider.candidate_version.should == @spec_version
    end

    it "parses the gem's specification if the requested source is a file" do
      @new_resource.package_name('chef-integration-test')
      @new_resource.version('>= 0')
      @new_resource.source(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
      @provider.candidate_version.should == '0.1.0'
    end

  end

  describe "when installing a gem" do
    before do
      @current_resource = Chef::Resource::GemPackage.new('rspec-core')
      @provider.current_resource = @current_resource
      @gem_dep = Gem::Dependency.new('rspec-core', @spec_version)
      @provider.stub!(:load_current_resource)
    end

    describe "in the current gem environment" do
      it "installs the gem via the gems api when no explicit options are used" do
        @provider.gem_env.should_receive(:install).with(@gem_dep, :sources => nil)
        @provider.action_install.should be_true
      end

      it "installs the gem via the gems api when a remote source is provided" do
        @new_resource.source('http://gems.example.org')
        sources = ['http://gems.example.org']
        @provider.gem_env.should_receive(:install).with(@gem_dep, :sources => sources)
        @provider.action_install.should be_true
      end

      it "installs the gem from file via the gems api when no explicit options are used" do
        @new_resource.source(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
        @provider.gem_env.should_receive(:install).with(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
        @provider.action_install.should be_true
      end

      it "installs the gem from file via the gems api when the package is a path and the source is nil" do
        @new_resource = Chef::Resource::GemPackage.new(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
        @provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
        @provider.current_resource = @current_resource
        @new_resource.source.should == CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem'
        @provider.gem_env.should_receive(:install).with(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
        @provider.action_install.should be_true
      end

      # this catches 'gem_package "foo"' when "./foo" is a file in the cwd, and instead of installing './foo' it fetches the remote gem
      it "installs the gem via the gems api, when the package has no file separator characters in it, but a matching file exists in cwd" do
        ::File.stub!(:exists?).and_return(true)
        @new_resource.package_name('rspec-core')
        @provider.gem_env.should_receive(:install).with(@gem_dep, :sources => nil)
        @provider.action_install.should be_true
      end

      it "installs the gem by shelling out when options are provided as a String" do
        @new_resource.options('-i /alt/install/location')
        expected ="gem install rspec-core -q --no-rdoc --no-ri -v \"#{@spec_version}\" -i /alt/install/location"
        @provider.should_receive(:shell_out!).with(expected, :env => nil)
        @provider.action_install.should be_true
      end

      it "installs the gem via the gems api when options are given as a Hash" do
        @new_resource.options(:install_dir => '/alt/install/location')
        @provider.gem_env.should_receive(:install).with(@gem_dep, :sources => nil, :install_dir => '/alt/install/location')
        @provider.action_install.should be_true
      end

      describe "at a specific version" do
        before do
          @gem_dep = Gem::Dependency.new('rspec-core', @spec_version)
        end

        it "installs the gem via the gems api" do
          @provider.gem_env.should_receive(:install).with(@gem_dep, :sources => nil)
          @provider.action_install.should be_true
        end
      end
      describe "at version specified with comparison operator" do
        it "skips install if current version satisifies requested version" do
          @current_resource.stub(:version).and_return("2.3.3")
          @new_resource.stub(:version).and_return(">=2.3.0")

          @provider.gem_env.should_not_receive(:install)
          @provider.action_install
        end

        it "allows user to specify gem version with fuzzy operator" do
          @current_resource.stub(:version).and_return("2.3.3")
          @new_resource.stub(:version).and_return("~>2.3.0")

          @provider.gem_env.should_not_receive(:install)
          @provider.action_install
        end
      end
    end

    describe "in an alternate gem environment" do
      it "installs the gem by shelling out to gem install" do
        @new_resource.gem_binary('/usr/weird/bin/gem')
        @provider.should_receive(:shell_out!).with("/usr/weird/bin/gem install rspec-core -q --no-rdoc --no-ri -v \"#{@spec_version}\"", :env=>nil)
        @provider.action_install.should be_true
      end

      it "installs the gem from file by shelling out to gem install" do
        @new_resource.gem_binary('/usr/weird/bin/gem')
        @new_resource.source(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
        @new_resource.version('>= 0')
        @provider.should_receive(:shell_out!).with("/usr/weird/bin/gem install #{CHEF_SPEC_DATA}/gems/chef-integration-test-0.1.0.gem -q --no-rdoc --no-ri -v \">= 0\"", :env=>nil)
        @provider.action_install.should be_true
      end

      it "installs the gem from file by shelling out to gem install when the package is a path and the source is nil" do
        @new_resource = Chef::Resource::GemPackage.new(CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem')
        @provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
        @provider.current_resource = @current_resource
        @new_resource.gem_binary('/usr/weird/bin/gem')
        @new_resource.version('>= 0')
        @new_resource.source.should == CHEF_SPEC_DATA + '/gems/chef-integration-test-0.1.0.gem'
        @provider.should_receive(:shell_out!).with("/usr/weird/bin/gem install #{CHEF_SPEC_DATA}/gems/chef-integration-test-0.1.0.gem -q --no-rdoc --no-ri -v \">= 0\"", :env=>nil)
        @provider.action_install.should be_true
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
        @provider.new_resource.version.should be_nil
        @provider.current_resource.version.should_not be_nil
        # the behavior we're testing:
        @provider.gem_env.should_receive(:uninstall).with('rspec', nil)
        @provider.action_remove
      end

      it "uninstalls via the api when options are given as a Hash" do
        # pre-reqs for action_remove to actually remove the package:
        @provider.new_resource.version.should be_nil
        @provider.current_resource.version.should_not be_nil
        # the behavior we're testing:
        @new_resource.options(:install_dir => '/alt/install/location')
        @provider.gem_env.should_receive(:uninstall).with('rspec', nil, :install_dir => '/alt/install/location')
        @provider.action_remove
      end

      it "uninstalls via the gem command when options are given as a String" do
        @new_resource.options('-i /alt/install/location')
        @provider.should_receive(:shell_out!).with("gem uninstall rspec -q -x -I -a -i /alt/install/location", :env=>nil)
        @provider.action_remove
      end

      it "uninstalls a specific version of a gem when a version is provided" do
        @new_resource.version('1.2.3')
        @provider.gem_env.should_receive(:uninstall).with('rspec', '1.2.3')
        @provider.action_remove
      end
    end

    describe "in an alternate gem environment" do
      it "uninstalls via the gem command" do
        @new_resource.gem_binary('/usr/weird/bin/gem')
        @provider.should_receive(:shell_out!).with("/usr/weird/bin/gem uninstall rspec -q -x -I -a", :env=>nil)
        @provider.action_remove
      end
    end
  end
end

