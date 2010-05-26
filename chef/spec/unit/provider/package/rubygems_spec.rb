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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))
require 'ostruct'

class String
  undef_method :version
end

describe Chef::Provider::Package::Rubygems::CurrentGemEnvironment do
  before do
    @gem_env = Chef::Provider::Package::Rubygems::CurrentGemEnvironment.new
  end

  it "determines the gem paths from the in memory rubygems" do
    @gem_env.gem_paths.should == Gem.path
  end

  it "determines the installed versions of gems from Gem.source_index" do
    gems = [Gem::Specification.new('rspec', Gem::Version.new('1.2.9')), Gem::Specification.new('rspec', Gem::Version.new('1.3.0'))]
    Gem.source_index.should_receive(:search).with(Gem::Dependency.new('rspec', nil)).and_return(gems)
    @gem_env.installed_versions('rspec').should == [Gem::Version.new('1.2.9'), Gem::Version.new('1.3.0')]
  end

  it "determines the installed versions of gems from the source index (part2: the unmockening)" do
    @gem_env.installed_versions('rspec').should include(Gem::Version.new(Spec::VERSION::STRING))
  end

end

describe Chef::Provider::Package::Rubygems::AlternateGemEnvironment do
  before do
    @gem_env = Chef::Provider::Package::Rubygems::AlternateGemEnvironment.new('/usr/weird/bin/gem')
  end

  it "determines the gem paths from shelling out to gem env" do
    gem_env_output = ['/path/to/gems', '/another/path/to/gems'].join(File::PATH_SEPARATOR)
    shell_out_result = OpenStruct.new(:stdout => gem_env_output)
    @gem_env.should_receive(:shell_out!).with('/usr/weird/bin/gem env gempath').and_return(shell_out_result)
    @gem_env.gem_paths.should == ['/path/to/gems', '/another/path/to/gems']
  end
  
  it "builds the gems source index from the gem paths" do
    Gem::SourceIndex.should_receive(:from_gems_in).with('/path/to/gems/specifications', '/another/path/to/gems/specifications')
    @gem_env.stub!(:gem_paths).and_return(['/path/to/gems', '/another/path/to/gems'])
    @gem_env.gem_source_index
  end
  
  it "determines the installed versions of gems from the source index" do
    gems = [Gem::Specification.new('rspec', Gem::Version.new('1.2.9')), Gem::Specification.new('rspec', Gem::Version.new('1.3.0'))]
    @gem_env.stub!(:gem_source_index).and_return(Gem.source_index)
    @gem_env.gem_source_index.should_receive(:search).with(Gem::Dependency.new('rspec', nil)).and_return(gems)
    @gem_env.installed_versions('rspec').should == [Gem::Version.new('1.2.9'), Gem::Version.new('1.3.0')]
  end

  it "determines the installed versions of gems from the source index (part2: the unmockening)" do
    path_to_gem = `which gem`.strip
    pending("cant find your gem executable") if path_to_gem.empty?
    gem_env = Chef::Provider::Package::Rubygems::AlternateGemEnvironment.new(path_to_gem)
    gem_env.installed_versions('rspec').should include(Gem::Version.new(Spec::VERSION::STRING))
  end

end

describe Chef::Provider::Package::Rubygems do
  before(:each) do
    @node = Chef::Node.new
    @new_resource = Chef::Resource::GemPackage.new("nokogiri")
    @new_resource.version "1.4.1"
    @run_context = Chef::RunContext.new(@node, {})
    
    @provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
  end

  it "uses the CurrentGemEnvironment implementation when no gem_binary_path is provided" do
    @provider.gem_implementation.should be_a_kind_of(Chef::Provider::Package::Rubygems::CurrentGemEnvironment)
  end

  it "uses the AlternateGemEnvironment implementation when a gem_binary_path is provided" do
    @new_resource.gem_binary('/usr/weird/bin/gem')
    provider = Chef::Provider::Package::Rubygems.new(@new_resource, @run_context)
    provider.gem_implementation.gem_binary_location.should == '/usr/weird/bin/gem'
  end

  # describe "loading the current state" do
  #   it "determines the installed versions of gems" do
  #     gem_list = "nokogiri (2.3.5, 2.2.2, 1.2.6)"
  #     @provider.gem_list_parse(gem_list).should == %w{2.3.5 2.2.2 1.2.6}
  #   end
  # end
  # 
  # describe "determining the candidate version" do
  #   it "parses the available versions as reported by rubygems 1.3.6 and lower" do
  #     gem_list = "nokogiri (1.4.1)\nnokogiri-happymapper (0.3.3)"
  #     @provider.gem_list_parse(gem_list).should == ['1.4.1']
  #   end
  # 
  #   it "parses the available versions as reported by rubygems 1.3.7 and newer" do
  #     gem_list = "nokogiri (1.4.1 ruby java x86-mingw32 x86-mswin32)\nnokogiri-happymapper (0.3.3)\n"
  #     @provider.gem_list_parse(gem_list).should == ['1.4.1']
  #   end
  # 
  # end
  # 
  # describe "when installing a gem" do
  #   it "should run gem install with the package name and version" do
  #     @provider.should_receive(:run_command).with(
  #       :command => "gem install rspec -q --no-rdoc --no-ri -v \"1.2.2\"",
  #       :environment => {"LC_ALL" => nil})
  #     @provider.install_package("rspec", "1.2.2")
  #   end
  # 
  #   it "installs gems with arbitrary options set by resource's options" do
  #     @new_resource.options "-i /arbitrary/install/dir"
  #     @provider.should_receive(:run_command_with_systems_locale).
  #       with(:command => "gem install rspec -q --no-rdoc --no-ri -v \"1.2.2\" -i /arbitrary/install/dir")
  #     @provider.install_package("rspec", "1.2.2")
  #   end
  # end
end
