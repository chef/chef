require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe MetricFu::LineNumbers do

  describe "in_method?" do
    it "should know if a line is NOT in a method" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/foo.rb"))
      ln.in_method?(2).should == false
    end

    it "should know if a line is in an instance method" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/foo.rb"))
      ln.in_method?(8).should == true
    end

    it "should know if a line is in an class method" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/foo.rb"))
      ln.in_method?(3).should == true
    end
  end

  describe "method_at_line" do
    it "should know the name of an instance method at a particular line" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/foo.rb"))
      ln.method_at_line(8).should == "Foo#what"
    end

    it "should know the name of a class method at a particular line" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/foo.rb"))
      ln.method_at_line(3).should == "Foo::awesome"
    end

    it "should know the name of a private method at a particular line" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/foo.rb"))
      ln.method_at_line(28).should == "Foo#whoop"
    end

    it "should know the name of a class method defined in a 'class << self block at a particular line" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/foo.rb"))
      ln.method_at_line(23).should == "Foo::neat"
    end

    it "should know the name of an instance method at a particular line in a file with two classes" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/two_classes.rb"))
      ln.method_at_line(3).should == "Foo#stuff"
      ln.method_at_line(9).should == "Bar#stuff"
    end

    it "should work with modules" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/module.rb"))
      ln.method_at_line(4).should == 'KickAss#get_beat_up?'
    end

    it "should work with module surrounding class" do
      ln = MetricFu::LineNumbers.new(File.read(File.dirname(__FILE__) + "/../resources/line_numbers/module_surrounds_class.rb"))
      ln.method_at_line(5).should == "StuffModule::ThingClass#do_it"
      # ln.method_at_line(12).should == "StuffModule#blah" #why no work?
    end

  end

end