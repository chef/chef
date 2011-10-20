require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
describe Flog do
  before :each do
    MetricFu::Configuration.run {}
    File.stub!(:directory?).and_return(true)
    @flog = MetricFu::Flog.new('base_dir')
  end

  describe "emit method" do
    it "should look for files and flog them" do
      Dir.should_receive(:glob).with("lib/**/*.rb").and_return(["found/file.rb"])
      ::Flog.should_receive(:parse_options).with(["--all", "--details"]).and_return("options")
      ::Flog.should_receive(:new).with("options").and_return(flogger = mock('flogger'))
      flogger.should_receive(:flog).with(["found/file.rb"])
      @flog.emit
    end
  end

  describe "analyze method" do
    it "should harvest the flog information and put it into method_containers" do
      first_full_method_name = "ClassName#first_method_name"
      second_full_method_name = "ClassName#second_method_name"

      flogger = mock('flogger', :calls => {first_full_method_name => {:branch => 11.1, :puts => 1.1},
                                           second_full_method_name => {:branch => 22.2, :puts => 2.2}},
                                :method_locations => {first_full_method_name => '/file/location.rb:11',
                                                      second_full_method_name => '/file/location.rb:22'},
                                :totals => {first_full_method_name => 11.11,
                                            second_full_method_name => 22.22})
      @flog.instance_variable_set(:@flogger, flogger)
      @flog.analyze
      method_containers = @flog.instance_variable_get(:@method_containers)
      method_containers.size.should == 1

      expected={:methods=>{"ClassName#first_method_name" => { :path=>"/file/location.rb:11",
                                                              :score=>11.11,
                                                              :operators=>{ :branch=>11.1,
                                                                            :puts=>1.1}},
                           "ClassName#second_method_name" => {:path=>"/file/location.rb:22",
                                                              :score=>22.22,
                                                              :operators=>{ :branch=>22.2,
                                                                            :puts=>2.2}}},
                :path=>"/file/location.rb",
                :average_score=>((11.11 + 22.22) / 2.0),
                :total_score=>33.33,
                :highest_score=>22.22,
                :name=>"ClassName"}

      method_containers["ClassName"].to_h.should == expected
    end
  end

  describe "to_h method" do
    it "should make-a nice hash" do
      flogger = mock('flogger', :total => 111.1, :average => 7.3)
      @flog.instance_variable_set(:@flogger, flogger)
      method_containers = {:ignore_me_1 =>  mock('container_1', :highest_score => 11.1, :to_h => 'container_1'),
                           :ignore_me_2 =>  mock('container_2', :highest_score => 33.3, :to_h => 'container_2'),
                           :ignore_me_3 =>  mock('container_3', :highest_score => 22.2, :to_h => 'container_3')}
      @flog.instance_variable_set(:@method_containers, method_containers)

      expected = {:flog => { :total => 111.1,
                  :average => 7.3,
                  :method_containers => ['container_2', 'container_3', 'container_1']}}

      @flog.to_h.should == expected
    end

  end
end
