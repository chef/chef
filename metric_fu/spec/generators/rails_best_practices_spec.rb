require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe RailsBestPractices do
  describe "emit method" do
    it "should gather the raw data" do
      MetricFu::Configuration.run {}
      practices = MetricFu::RailsBestPractices.new
      practices.should_receive(:`).with("rails_best_practices --without-color .")
      practices.emit
    end
  end

  describe "analyze method" do
    before :each do
      output = <<-HERE.gsub(/^[^\S\n]*/, "")
      ./app/views/admin/testimonials/_form.html.erb:17 - replace instance variable with local variable
      ./app/controllers/admin/campaigns_controller.rb:24,45,68,85 - use before_filter for show,edit,update,destroy

      go to http://wiki.github.com/flyerhzm/rails_best_practices to see how to solve these errors.

      Found 2 errors.
      HERE
      MetricFu::Configuration.run {}
      practices = MetricFu::RailsBestPractices.new
      practices.instance_variable_set(:@output, output)
      @results = practices.analyze
    end

    it "should get the total" do
      @results[:total].should == ["Found 2 errors."]
    end

    it "should get the problems" do
      @results[:problems].size.should == 2
      @results[:problems].first.should == { :line => "17",
        :problem => "replace instance variable with local variable",
        :file => "app/views/admin/testimonials/_form.html.erb" }
      @results[:problems][1].should == { :line => "24,45,68,85",
        :problem => "use before_filter for show,edit,update,destroy",
        :file => "app/controllers/admin/campaigns_controller.rb" }
    end
  end

  describe "to_h method" do
    it "should put things into a hash" do
      MetricFu::Configuration.run {}
      practices = MetricFu::RailsBestPractices.new
      practices.instance_variable_set(:@rails_best_practices_results, "the_practices")
      practices.to_h[:rails_best_practices].should == "the_practices"
    end
  end
end
