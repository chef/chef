require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Saikuro do
  describe "to_h method" do
    before :all do
      MetricFu::Configuration.run {}
      File.stub!(:directory?).and_return(true)
      saikuro = MetricFu::Saikuro.new
      saikuro.stub!(:metric_directory).and_return(File.join(File.dirname(__FILE__), "..", "resources", "saikuro"))
      saikuro.analyze
      @output = saikuro.to_h
    end

    it "should find the filename of a file" do
      @output[:saikuro][:files].first[:filename].should == 'app/controllers/users_controller.rb'
    end

    it "should find the name of the classes" do
      @output[:saikuro][:classes].first[:name].should == "UsersController"
      @output[:saikuro][:classes][1][:name].should == "SessionsController"
    end

    it "should put the most complex method first" do
      @output[:saikuro][:methods].first[:name].should == "UsersController#create"
      @output[:saikuro][:methods].first[:complexity].should == 4
    end

    it "should find the complexity of a method" do
      @output[:saikuro][:methods].first[:complexity].should == 4
    end

    it "should find the lines of a method" do
      @output[:saikuro][:methods].first[:lines].should == 15
    end
  end
  
  describe "per_file_info method" do
    before :all do
      MetricFu::Configuration.run {}
      File.stub!(:directory?).and_return(true)
      @saikuro = MetricFu::Saikuro.new
      @saikuro.stub!(:metric_directory).and_return(File.join(File.dirname(__FILE__), "..", "resources", "saikuro"))
      @saikuro.analyze
      @output = @saikuro.to_h
    end
    
    it "doesn't try to get information if the file does not exist" do
      File.should_receive(:exists?).at_least(:once).and_return(false)
      @saikuro.per_file_info('ignore_me')
    end
  end

  describe "format_directories method" do
    it "should format the directories" do
      MetricFu::Configuration.run {}
      File.stub!(:directory?).and_return(true)
      saikuro = MetricFu::Saikuro.new

      MetricFu.saikuro[:input_directory] = ["app", "lib"]

      saikuro.format_directories.should == "\"app | lib\""
    end
  end

  describe Saikuro::SFile do
    describe "getting elements from a Saikuro result file" do
     it "should parse nested START/END sections" do
       path = File.join(File.dirname(__FILE__), "..", "resources", "saikuro_sfiles", "thing.rb_cyclo.html")
        sfile = Saikuro::SFile.new path
       sfile.elements.map { |e| e.complexity }.sort.should eql(["0","0","2"])
      end
    end
  end
end
