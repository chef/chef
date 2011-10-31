require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe MetricFu::Location do

  context "with non-standard Reek method names" do
    # reek reports the method with :: not # on modules like 
    # module ApplicationHelper \n def signed_in?, convert it so it records correctly
    # class_or_method_name = class_or_method_name.gsub(/\:\:/,"#") if method_bug_conversion

    before do
      @location = Location.for("ApplicationHelper::section_link")
    end

    it "has method name" do
      @location.method_name.should == 'ApplicationHelper#section_link'
    end

    it "has nil file path" do
      @location.file_path.should   == nil
    end

    it "has class name" do
      @location.class_name.should  == 'ApplicationHelper'
    end
    
  end

  context "using new" do
    
    before do 
      @location = Location.new("lib/foo.rb", "Foo", "Foo#some_method")
    end

    it "should return fully qualified method" do
      @location.method_name.should == 'Foo#some_method'
    end
    
  end

  context "using .for with class" do

    before do 
      @location = Location.for("Module::Foo")
    end

    it "has nil method_name" do
      @location.method_name.should be nil
    end

    it "has nil file_path" do
      @location.file_path.should be nil
    end

    it "has class_name" do
      @location.class_name.should == 'Foo'
    end

  end

  context "using .for with method" do
    
    before do 
      @location = Location.for("Module::Foo#some_method")
    end

    it "strips module from class name" do
      @location.class_name.should == 'Foo'
    end

    it "strips module from method name" do
      @location.method_name.should == 'Foo#some_method'
    end

    it "has nil file_path" do
      @location.file_path.should be nil
    end

  end

  context "with class method" do
    
    it "provides non-qualified name" do
      location = Location.for("Foo.some_class_method")
      location.simple_method_name.should == '.some_class_method'
    end

  end

  context "with instance method" do
    
    it "provides non-qualified name" do
      location = Location.for("Foo#some_class_method")
      location.simple_method_name.should == '#some_class_method'
    end

  end

end
