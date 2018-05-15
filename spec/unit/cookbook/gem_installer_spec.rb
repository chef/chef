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
          gems: [["httpclient", ">= 1.0"]]
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
    expect(gem_installer).to receive(:shell_out!).and_return(shell_out)

  end

  it "generates a valid Gemfile" do
    expect { gem_installer.install }.to_not raise_error

    expect { bundler_dsl }.to_not raise_error
  end

  it "generate a Gemfile with all constraints" do
    expect { gem_installer.install }.to_not raise_error

    expect(bundler_dsl.dependencies.find { |d| d.name == "httpclient" }.requirements_list.length).to eql(2)
  end

  it "generates a valid Gemfile when Chef::Config[:rubygems_url] is set to a String" do
    Chef::Config[:rubygems_url] = "https://www.rubygems.org"
    expect { gem_installer.install }.to_not raise_error

    expect(bundler_dsl.dependencies.find { |d| d.name == "httpclient" }.requirements_list.length).to eql(2)
  end

  it "generates a valid Gemfile when Chef::Config[:rubygems_url] is set to an Array" do
    Chef::Config[:rubygems_url] = [ "https://www.rubygems.org" ]

    expect { gem_installer.install }.to_not raise_error

    expect(bundler_dsl.dependencies.find { |d| d.name == "httpclient" }.requirements_list.length).to eql(2)
  end
end
