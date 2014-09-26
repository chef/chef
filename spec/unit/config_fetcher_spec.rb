require 'spec_helper'
require 'chef/config_fetcher'
describe Chef::ConfigFetcher do
  let(:valid_json) { Chef::JSONCompat.to_json({:a=>"b"}) }
  let(:invalid_json) { %q[{"syntax-error": "missing quote}] }
  let(:http) { double("Chef::HTTP::Simple") }

  let(:config_location_regex) { Regexp.escape(config_location) }
  let(:invalid_json_error_regex) { %r[Could not parse the provided JSON file \(#{config_location_regex}\)] }

  let(:config_jail_path) { nil }

  let(:fetcher) { Chef::ConfigFetcher.new(config_location, config_jail_path) }

  context "when loading a local file" do
    let(:config_location) { "/etc/chef/client.rb" }
    let(:config_content) { "# The client.rb content" }

    it "reads the file from disk" do
      ::File.should_receive(:read).
        with(config_location).
        and_return(config_content)
      fetcher.read_config.should == config_content
    end

    context "and consuming JSON" do

      let(:config_location) { "/etc/chef/first-boot.json" }


      it "returns the parsed JSON" do
        ::File.should_receive(:read).
          with(config_location).
          and_return(valid_json)

        fetcher.fetch_json.should == {"a" => "b"}
      end

      context "and the JSON is invalid" do

        it "reports the JSON error" do


          ::File.should_receive(:read).
            with(config_location).
            and_return(invalid_json)

          Chef::Application.should_receive(:fatal!).
            with(invalid_json_error_regex, 2)
          fetcher.fetch_json
        end
      end
    end

  end

  context "when loading a file over HTTP" do

    let(:config_location) { "https://example.com/client.rb" }
    let(:config_content) { "# The client.rb content" }

    before do
      Chef::HTTP::Simple.should_receive(:new).
        with(config_location).
        and_return(http)
    end

    it "reads the file over HTTP" do
        http.should_receive(:get).
          with("").and_return(config_content)
      fetcher.read_config.should == config_content
    end

    context "and consuming JSON" do
      let(:config_location) { "https://example.com/foo.json" }

      it "fetches the file and parses it" do
        http.should_receive(:get).
          with("").and_return(valid_json)
        fetcher.fetch_json.should == {"a" => "b"}
      end

      context "and the JSON is invalid" do
        it "reports the JSON error" do
          http.should_receive(:get).
            with("").and_return(invalid_json)

          Chef::Application.should_receive(:fatal!).
            with(invalid_json_error_regex, 2)
          fetcher.fetch_json
        end
      end
    end

  end


end
