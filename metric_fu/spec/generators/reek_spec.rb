require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Reek do
  describe "emit" do
    it "should include config parameters" do
      MetricFu::Configuration.run do |config|
        config.reek = {:config_file_pattern => 'lib/config/*.reek', :dirs_to_reek => []}
      end
      reek = MetricFu::Reek.new
      reek.should_receive(:`).with(/--config lib\/config\/\*\.reek/).and_return("")
      reek.emit
    end
  end

  describe "analyze method" do
    before :each do
      @lines = <<-HERE
"app/controllers/activity_reports_controller.rb" -- 4 warnings:
ActivityReportsController#authorize_user calls current_user.primary_site_ids multiple times (Duplication)
ActivityReportsController#authorize_user calls params[id] multiple times (Duplication)
ActivityReportsController#authorize_user calls params[primary_site_id] multiple times (Duplication)
ActivityReportsController#authorize_user has approx 6 statements (Long Method)

"app/controllers/application.rb" -- 1 warnings:
ApplicationController#start_background_task/block/block is nested (Nested Iterators)

"app/controllers/link_targets_controller.rb" -- 1 warnings:
LinkTargetsController#authorize_user calls current_user.role multiple times (Duplication)

"app/controllers/newline_controller.rb" -- 1 warnings:
NewlineController#some_method calls current_user.<< "new line\n" multiple times (Duplication)
      HERE
      MetricFu::Configuration.run {}
      File.stub!(:directory?).and_return(true)
      reek = MetricFu::Reek.new
      reek.instance_variable_set(:@output, @lines)
      @matches = reek.analyze
    end

    it "should find the code smell's method name" do
      smell = @matches.first[:code_smells].first
      smell[:method].should == "ActivityReportsController#authorize_user"
    end

    it "should find the code smell's type" do
      smell = @matches[1][:code_smells].first
      smell[:type].should == "Nested Iterators"
    end

    it "should find the code smell's message" do
      smell = @matches[1][:code_smells].first
      smell[:message].should == "is nested"
    end

    it "should find the code smell's type" do
      smell = @matches.first
      smell[:file_path].should == "app/controllers/activity_reports_controller.rb"
    end

    it "should NOT insert nil smells into the array when there's a newline in the method call" do
      @matches.last[:code_smells].should == @matches.last[:code_smells].compact
      @matches.last.should == {:file_path=>"app/controllers/newline_controller.rb",
                                :code_smells=>[{:type=>"Duplication",
                                                  :method=>"\"",
                                                  :message=>"multiple times"}]}
      # Note: hopefully a temporary solution until I figure out how to deal with newlines in the method call more effectively -Jake 5/11/2009
    end
  end

end

describe Reek do
  before :each do
    MetricFu::Configuration.run {}
    @reek = MetricFu::Reek.new
    @lines11 = <<-HERE
"app/controllers/activity_reports_controller.rb" -- 4 warnings:
ActivityReportsController#authorize_user calls current_user.primary_site_ids multiple times (Duplication)
ActivityReportsController#authorize_user calls params[id] multiple times (Duplication)
ActivityReportsController#authorize_user calls params[primary_site_id] multiple times (Duplication)
ActivityReportsController#authorize_user has approx 6 statements (Long Method)

"app/controllers/application.rb" -- 1 warnings:
ApplicationController#start_background_task/block/block is nested (Nested Iterators)

"app/controllers/link_targets_controller.rb" -- 1 warnings:
LinkTargetsController#authorize_user calls current_user.role multiple times (Duplication)

"app/controllers/newline_controller.rb" -- 1 warnings:
NewlineController#some_method calls current_user.<< "new line\n" multiple times (Duplication)
      HERE
    @lines12 = <<-HERE
app/controllers/activity_reports_controller.rb -- 4 warnings (+3 masked):
  ActivityReportsController#authorize_user calls current_user.primary_site_ids multiple times (Duplication)
  ActivityReportsController#authorize_user calls params[id] multiple times (Duplication)
  ActivityReportsController#authorize_user calls params[primary_site_id] multiple times (Duplication)
  ActivityReportsController#authorize_user has approx 6 statements (Long Method)
app/controllers/application.rb -- 1 warnings:
  ApplicationController#start_background_task/block/block is nested (Nested Iterators)
app/controllers/link_targets_controller.rb -- 1 warnings (+1 masked):
  LinkTargetsController#authorize_user calls current_user.role multiple times (Duplication)
app/controllers/newline_controller.rb -- 1 warnings:
  NewlineController#some_method calls current_user.<< "new line\n" multiple times (Duplication)
      HERE
  end

  context 'with Reek 1.1 output format' do
    it 'reports 1.1 style when the output is empty' do
      @reek.instance_variable_set(:@output, "")
      @reek.should_not be_reek_12
    end
    it 'detects 1.1 format output' do
      @reek.instance_variable_set(:@output, @lines11)
      @reek.should_not be_reek_12
    end

    it 'massages empty output to be unchanged' do
      @reek.instance_variable_set(:@output, "")
      @reek.massage_for_reek_12.should be_empty
    end
  end

  context 'with Reek 1.2 output format' do
    it 'detects 1.2 format output' do
      @reek.instance_variable_set(:@output, @lines12)
      @reek.should be_reek_12
    end

    it 'correctly massages 1.2 output' do
      @reek.instance_variable_set(:@output, @lines12)
      @reek.massage_for_reek_12.should == @lines11
    end
  end
end
