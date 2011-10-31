require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Roodi do
  describe "emit" do
    it "should add config options when present" do
      MetricFu::Configuration.run do |config|
        config.roodi = {:roodi_config => 'lib/config/roodi_config.yml', :dirs_to_roodi => []}
      end
      roodi = MetricFu::Roodi.new
      roodi.should_receive(:`).with(/-config=lib\/config\/roodi_config\.yml/).and_return("")
      roodi.emit
    end

    it "should NOT add config options when NOT present" do
      MetricFu::Configuration.run do |config|
        config.roodi = {:dirs_to_roodi => []}
      end
      roodi = MetricFu::Roodi.new
      roodi.stub(:`)
      roodi.should_receive(:`).with(/-config/).never
      roodi.emit
    end
  end
end