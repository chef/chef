require "spec_helper"
require "bundler/dsl"

describe Chef::Cookbook::GemInstaller do
  let(:cookbook_collection) do
    {
      test: double(
        :cookbook,
        metadata: double(
          :metadata,
          gems: [["httpclient"], ["nokogiri"]]
        )
      ),
      test2: double(
        :cookbook,
        metadata: double(
          :metadata,
          gems: [["httpclient", ">= 2.0"]]
        )
      ),
      test3: double(
        :cookbook,
        metadata: double(
          :metadata,
          gems: [["httpclient", ">= 1.0", { "git" => "https://github.com/nahi/httpclient" }]]
        )
      ),
      test4: double(
        :cookbook,
        metadata: double(
          :metadata,
          gems: [["httpclient", { "path" => "./gems/httpclient" }]]
        )
      ),
    }
  end

  let(:gem_installer) do
    described_class.new(cookbook_collection, Chef::EventDispatch::Dispatcher.new)
  end

  let(:gemfile) do
    StringIO.new
  end

  let(:shell_out) do
    double(:shell_out, stdout: "")
  end

  let(:bundler_dsl) do
    b = Bundler::Dsl.new
    b.instance_eval(gemfile.string)
    b
  end

  before(:each) do
    # Prepare mocks: using a StringIO instead of a File
    expect(Dir).to receive(:mktmpdir).and_yield("")
    expect(File).to receive(:open).and_yield(gemfile)
    expect(gemfile).to receive(:path).and_return("")
    expect(IO).to receive(:read).and_return("")

  end

  it "generates a valid Gemfile" do
    expect(gem_installer).to receive(:shell_out!).and_return(shell_out)
    expect { gem_installer.install }.to_not raise_error

    expect { bundler_dsl }.to_not raise_error
  end

  it "generate a Gemfile with all constraints" do
    expect(gem_installer).to receive(:shell_out!).and_return(shell_out)
    expect { gem_installer.install }.to_not raise_error

    expect(bundler_dsl.dependencies.find { |d| d.name == "httpclient" }.requirements_list.length).to eql(2)
  end

  it "generates a valid Gemfile when Chef::Config[:rubygems_url] is set to a String" do
    expect(gem_installer).to receive(:shell_out!).and_return(shell_out)
    Chef::Config[:rubygems_url] = "https://www.rubygems.org"
    expect { gem_installer.install }.to_not raise_error

    expect(bundler_dsl.dependencies.find { |d| d.name == "httpclient" }.requirements_list.length).to eql(2)
  end

  it "generates a valid Gemfile when Chef::Config[:rubygems_url] is set to an Array" do
    expect(gem_installer).to receive(:shell_out!).and_return(shell_out)
    Chef::Config[:rubygems_url] = [ "https://www.rubygems.org" ]

    expect { gem_installer.install }.to_not raise_error

    expect(bundler_dsl.dependencies.find { |d| d.name == "httpclient" }.requirements_list.length).to eql(2)
  end

  it "skip metadata installation when Chef::Config[:skip_gem_metadata_installation] is set to true" do
    Chef::Config[:skip_gem_metadata_installation] = true
    expect(gem_installer.install).to_not receive(:shell_out!)
  end

  it "install metadata when Chef::Config[:skip_gem_metadata_installation] is not true" do
    expect(gem_installer).to receive(:shell_out!).and_return(shell_out)
    expect(Chef::Log).to receive(:info).and_return("")
    expect(gem_installer.install).to be_nil
  end

  it "install from local cache when Chef::Config[:gem_installer_bundler_options] is set to local" do
    Chef::Config[:gem_installer_bundler_options] = "--local"
    expect(gem_installer).to receive(:shell_out!).with(["bundle", "install", "--local"], any_args).and_return(shell_out)
    expect(Chef::Log).to receive(:info).and_return("")
    expect(gem_installer.install).to be_nil
  end
end
