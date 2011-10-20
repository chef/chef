require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe MetricFu::Rcov do

  before :each do
    MetricFu::Configuration.run {}
    File.stub!(:directory?).and_return(true)
    @rcov = MetricFu::Rcov.new('base_dir')
  end

  describe "emit" do
    before :each do
      @rcov.stub!(:puts)
      MetricFu.rcov[:external] = nil
    end

    it "should clear out previous output and make output folder" do
      @rcov.stub!(:`)
      FileUtils.should_receive(:rm_rf).with(MetricFu::Rcov.metric_directory, :verbose => false)
      Dir.should_receive(:mkdir).with(MetricFu::Rcov.metric_directory)
      @rcov.emit
    end

    it "should set the RAILS_ENV" do
      FileUtils.stub!(:rm_rf)
      Dir.stub!(:mkdir)
      MetricFu.rcov[:environment] = "metrics"
      @rcov.should_receive(:`).with(/RAILS_ENV=metrics/)
      @rcov.emit
    end
  end

  describe "with RCOV_OUTPUT fed into" do
    before :each do
      MetricFu.rcov[:external] = nil
      File.should_receive(:open).
            with(MetricFu::Rcov.metric_directory + '/rcov.txt').
            and_return(mock("io", :read => RCOV_OUTPUT))
      @files = @rcov.analyze
    end

    describe "analyze" do
      it "should compute percent of lines run" do
        @files["lib/templates/awesome/awesome_template.rb"][:percent_run].should == 13
        @files["lib/templates/standard/standard_template.rb"][:percent_run].should == 14
      end

      it "should know which lines were run" do
        @files["lib/templates/awesome/awesome_template.rb"][:lines].
              should include({:content=>"require 'fileutils'", :was_run=>true})
      end

      it "should know which lines NOT were run" do
        @files["lib/templates/awesome/awesome_template.rb"][:lines].
              should include({:content=>"      if template_exists?(section)", :was_run=>false})
      end
    end

    describe "to_h" do
      it "should calculate total percentage for all files" do
        @rcov.to_h[:rcov][:global_percent_run].should == 13.7
      end
    end
  end
  describe "with external configuration option set" do
    before :each do
      @rcov.stub!(:puts)
      MetricFu.rcov[:external] = "coverage/rcov.txt"
    end

    it "should emit nothing if external configuration option is set" do
      FileUtils.should_not_receive(:rm_rf)
      @rcov.emit
    end

    it "should open the external rcov analysis file" do
      File.should_receive(:open).
            with(MetricFu.rcov[:external]).
            and_return(mock("io", :read => RCOV_OUTPUT))
      @files = @rcov.analyze
    end

  end


RCOV_OUTPUT = <<-HERE
Profiling enabled.
.............................................................................................................................................................................................


Top 10 slowest examples:
0.2707830 MetricFu::RoodiGrapher responding to #get_metrics should push 13 to roodi_count
0.1994550 MetricFu::RcovGrapher responding to #get_metrics should update labels with the date
0.1985800 MetricFu::ReekGrapher responding to #get_metrics should set a hash of code smells to reek_count
0.1919860 MetricFu::ReekGrapher responding to #get_metrics should update labels with the date
0.1907400 MetricFu::RoodiGrapher responding to #get_metrics should update labels with the date
0.1883000 MetricFu::FlogGrapher responding to #get_metrics should update labels with the date
0.1882650 MetricFu::FlayGrapher responding to #get_metrics should push 476 to flay_score
0.1868780 MetricFu::FlogGrapher responding to #get_metrics should push to top_five_percent_average
0.1847730 MetricFu::FlogGrapher responding to #get_metrics should push 9.9 to flog_average
0.1844090 MetricFu::FlayGrapher responding to #get_metrics should update labels with the date

Finished in 2.517686 seconds

189 examples, 0 failures
================================================================================
lib/templates/awesome/awesome_template.rb
================================================================================
   require 'fileutils'

   class AwesomeTemplate < MetricFu::Template

     def write
!!     # Getting rid of the crap before and after the project name from integrity
!!     @name = File.basename(Dir.pwd).gsub(/^\w+-|-\w+$/, "")
!!
!!     # Copy Bluff javascripts to output directory
!!     Dir[File.join(this_directory, '..', 'javascripts', '*')].each do |f|
!!       FileUtils.copy(f, File.join(MetricFu.output_directory, File.basename(f)))
!!     end
!!
!!     report.each_pair do |section, contents|
!!       if template_exists?(section)
!!         create_instance_var(section, contents)
!!         @html = erbify(section)
!!         html = erbify('layout')
!!         fn = output_filename(section)
!!         MetricFu.report.save_output(html, MetricFu.output_directory, fn)
!!       end
!!     end
!!
!!     # Instance variables we need should already be created from above
!!     if template_exists?('index')
!!       @html = erbify('index')
!!       html = erbify('layout')
!!       fn = output_filename('index')
!!       MetricFu.report.save_output(html, MetricFu.output_directory, fn)
!!     end
!!   end

     def this_directory
!!     File.dirname(__FILE__)
!!   end
!! end

================================================================================
lib/templates/standard/standard_template.rb
================================================================================
   class StandardTemplate < MetricFu::Template


     def write
!!     report.each_pair do |section, contents|
!!       if template_exists?(section)
!!         create_instance_var(section, contents)
!!         html = erbify(section)
!!         fn = output_filename(section)
!!         MetricFu.report.save_output(html, MetricFu.output_directory, fn)
!!       end
!!     end
!!
!!     # Instance variables we need should already be created from above
!!     if template_exists?('index')
!!       html = erbify('index')
!!       fn = output_filename('index')
!!       MetricFu.report.save_output(html, MetricFu.output_directory, fn)
!!     end
!!   end

     def this_directory
!!     File.dirname(__FILE__)
!!   end
!! end

HERE

end



