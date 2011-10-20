require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe MetricFu do

  describe "#report" do
    it 'should return an instance of Report' do
      MetricFu.report.instance_of?(Report).should be(true)
    end
  end
end

describe MetricFu::Report do

  before(:each) do
    @report = MetricFu::Report.new
  end

  describe "#to_yaml" do
    it 'should call #report_hash' do
      report_hash = mock('report_hash')
      report_hash.should_receive(:to_yaml)
      @report.should_receive(:report_hash).and_return(report_hash)
      @report.to_yaml
    end
  end

  describe "#report_hash" do
  end

  describe "#save_templatized_report" do
    it 'should create a new template class assign a report_hash '\
       'to the template class, and ask it to write itself out' do
      template_class = mock('template_class')
      template_class.should_receive(:new).and_return(template_class)
      MetricFu.should_receive(:template_class).and_return(template_class)
      template_class.should_receive(:report=)
      template_class.should_receive(:per_file_data=)
      template_class.should_receive(:write)
      @report.save_templatized_report
    end
  end

  describe "#add" do
    it 'should add a passed hash to the report_hash instance variable' do
      report_type = mock('report_type')
      report_type.should_receive(:to_s).and_return('type')

      report_inst = mock('report_inst')
      report_type.should_receive(:new).and_return(report_inst)

      report_inst.should_receive(:generate_report).and_return({:a => 'b'})
      report_inst.should_receive(:respond_to?).and_return(false)

      MetricFu.should_receive(:const_get).
               with('Type').and_return(report_type)
      report_hash = mock('report_hash')
      report_hash.should_receive(:merge!).with({:a => 'b'})
      @report.should_receive(:report_hash).and_return(report_hash)
      @report.add(report_type)
    end
  end

  describe "#save_output" do
    it 'should write the passed content to dir/index.html' do
      f = mock('file')
      content = 'content'
      @report.should_receive(:open).with('dir/file', 'w').and_yield(f)
      f.should_receive(:puts).with(content)
      @report.save_output(content, 'dir', 'file')
    end
  end

  describe '#open_in_browser? ' do

    before(:each) do
      @config = mock('configuration')
    end

    describe 'when the platform is os x ' do

      before(:each) do
        @config.should_receive(:platform).and_return('darwin')
      end

      describe 'and we are in cruise control ' do

        before(:each) do
          @config.should_receive(:is_cruise_control_rb?).and_return(true)
          MetricFu.stub!(:configuration).and_return(@config)
        end

        it 'should return false' do
          @report.open_in_browser?.should be_false
        end
      end

      describe 'and we are not in cruise control' do

        before(:each) do
          @config.should_receive(:is_cruise_control_rb?).and_return(false)
          MetricFu.stub!(:configuration).and_return(@config)
        end

        it 'should return true' do
          @report.open_in_browser?.should be_true
        end
      end
    end

    describe 'when the platform is not os x ' do
      before(:each) do
        @config.should_receive(:platform).and_return('other')
      end

      describe 'and we are in cruise control' do
        before(:each) do
          MetricFu.stub!(:configuration).and_return(@config)
        end

        it 'should return false' do
          @report.open_in_browser?.should be_false
        end
      end

      describe 'and we are not in cruise control' do
        before(:each) do
          MetricFu.stub!(:configuration).and_return(@config)
        end

        it 'should return false' do
          @report.open_in_browser?.should be_false
        end
      end
    end
  end


  describe '#show_in_browser' do
    it 'should call open with the passed directory' do
      @report.should_receive(:open_in_browser?).and_return(true)
      @report.should_receive(:system).with("open my_dir/index.html")
      @report.show_in_browser('my_dir')
    end

  end
end
