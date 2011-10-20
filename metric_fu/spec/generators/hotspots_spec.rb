require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Hotspots do

  describe "analyze method" do
    before :each do
      MetricFu::Configuration.run {}
      File.stub!(:directory?).and_return(true)
      @yaml =<<END
--- 
:reek: 
  :matches: 
  - :file_path: lib/client/client.rb
    :code_smells: 
    - :type: Large Class
      :message: has at least 27 methods
      :method: Devver::Client
    - :type: Long Method
      :message: has approx 6 statements
      :method: Devver::Client#client_requested_sync
:flog: 
  :method_containers: 
  - :highest_score: 61.5870319141946
    :path: /lib/client/client.rb
    :methods: 
      Client#client_requested_sync: 
        :path: /lib/client/client.rb
        :score: 37.9270319141946
        :operators: 
          :+: 1.70000000000001
          :/: 1.80000000000001
          :method_at_line: 1.90000000000001
          :puts: 1.70000000000001
          :assignment: 33.0000000000001
          :in_method?: 1.70000000000001
          :message: 1.70000000000001
          :branch: 12.6
          :<<: 3.40000000000001
          :each: 1.50000000000001
          :lit_fixnum: 1.45
          :raise: 1.80000000000001
          :each_pair: 1.3
          :*: 1.60000000000001
          :to_f: 2.00000000000001
          :each_with_index: 3.00000000000001
          :[]: 22.3000000000001
          :new: 1.60000000000001
    :average_score: 11.1209009055421
    :total_score: 1817.6
    :name: Client#client_requested_sync
:churn: 
  :changes: 
  - :file_path: lib/client/client.rb
    :times_changed: 54
  - :file_path: lib/client/foo.rb
    :times_changed: 52
END
    end

    it "should be empty on error" do
      hotspots = MetricFu::Hotspots.new
      hotspots.instance_variable_set(:@analyzer, nil)
      result = hotspots.analyze
      result.should == {}
    end

    it "should return yaml results" do
      hotspots = MetricFu::Hotspots.new
      analyzer = MetricAnalyzer.new(@yaml)
      hotspots.instance_variable_set(:@analyzer, analyzer)
      result = hotspots.analyze
      #TODO better way to compare hashes? straight hash compare isn't in the same order so it fails?
      JSON.parse(result.to_json).should == JSON.parse("{\"methods\":[{\"location\":{\"class_name\":\"Client\",\"method_name\":\"Client#client_requested_sync\",\"file_path\":\"lib/client/client.rb\",\"hash\":7919384682,\"simple_method_name\":\"#client_requested_sync\"},\"details\":{\"reek\":\"found 1 code smells\",\"flog\":\"complexity is 37.9\"}}],\"classes\":[{\"location\":{\"class_name\":\"Client\",\"method_name\":null,\"file_path\":\"lib/client/client.rb\",\"hash\":7995629750},\"details\":{\"reek\":\"found 2 code smells\",\"flog\":\"complexity is 37.9\"}}],\"files\":[{\"location\":{\"class_name\":null,\"method_name\":null,\"file_path\":\"lib/client/client.rb\",\"hash\":-5738801681},\"details\":{\"reek\":\"found 2 code smells\",\"flog\":\"complexity is 37.9\",\"churn\":\"detected high level of churn (changed 54 times)\"}},{\"location\":{\"class_name\":null,\"method_name\":null,\"file_path\":\"lib/client/foo.rb\",\"hash\":-7081271905},\"details\":{\"churn\":\"detected high level of churn (changed 52 times)\"}}]}")
    end

    it "should put the changes into a hash" do
      hotspots = MetricFu::Hotspots.new
      analyzer = MetricAnalyzer.new(@yaml)
      hotspots.instance_variable_set(:@analyzer, analyzer)
      hotspots.analyze
      JSON.parse(hotspots.to_h[:hotspots].to_json).should == JSON.parse("{\"methods\":[{\"location\":{\"class_name\":\"Client\",\"method_name\":\"Client#client_requested_sync\",\"file_path\":\"lib/client/client.rb\",\"hash\":7919384682,\"simple_method_name\":\"#client_requested_sync\"},\"details\":{\"reek\":\"found 1 code smells\",\"flog\":\"complexity is 37.9\"}}],\"classes\":[{\"location\":{\"class_name\":\"Client\",\"method_name\":null,\"file_path\":\"lib/client/client.rb\",\"hash\":7995629750},\"details\":{\"reek\":\"found 2 code smells\",\"flog\":\"complexity is 37.9\"}}],\"files\":[{\"location\":{\"class_name\":null,\"method_name\":null,\"file_path\":\"lib/client/client.rb\",\"hash\":-5738801681},\"details\":{\"reek\":\"found 2 code smells\",\"flog\":\"complexity is 37.9\",\"churn\":\"detected high level of churn (changed 54 times)\"}},{\"location\":{\"class_name\":null,\"method_name\":null,\"file_path\":\"lib/client/foo.rb\",\"hash\":-7081271905},\"details\":{\"churn\":\"detected high level of churn (changed 52 times)\"}}]}")
    end
  end
end

