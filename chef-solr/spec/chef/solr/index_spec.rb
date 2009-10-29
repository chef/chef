require File.expand_path(File.join("#{File.dirname(__FILE__)}", '..', '..', 'spec_helper'))

describe Chef::Solr::Index do
  before(:each) do
    @index = Chef::Solr::Index.new
  end

  describe "initialize" do
    it "should return a Chef::Solr::Index" do
      @index.should be_a_kind_of(Chef::Solr::Index)
    end
  end

  describe "add" do
    before(:each) do
      @index.stub!(:solr_add).and_return(true)
      @index.stub!(:solr_commit).and_return(true)
    end

    it "should take an object that responds to .keys as it's argument" do
      lambda { @index.add(1, "chef_opscode", "node", { :one => :two }) }.should_not raise_error(ArgumentError)
      lambda { @index.add(1, "chef_opscode", "node", "SOUP") }.should raise_error(ArgumentError)
      lambda { @index.add(2, "chef_opscode", "node", mock("Foo", :keys => true)) }.should_not raise_error(ArgumentError)
    end

    it "should index the object as a single flat hash, with only strings or arrays as values" do
      validate = {
        "X_CHEF_id_CHEF_X" => 1,
        "X_CHEF_database_CHEF_X" => "monkey",
        "X_CHEF_type_CHEF_X" => "snakes", 
        "foo" => "bar",
        "battles" => [ "often", "but", "for" ],
        "battles_often" => "sings like smurfs",
        "often" => "sings like smurfs",
        "battles_but" => "still has good records",
        "but" => "still has good records",
        "battles_for" => [ "all", "of", "that" ],
        "for" => [ "all", "of", "that" ],
        "snoopy" => "sits_in_a_barn",
        "battles_X" => [ "sings like smurfs", "still has good records", "all", "of", "that" ],
        "X_often" => "sings like smurfs",
        "X_but" => "still has good records",
        "X_for" => [ "all", "of", "that" ]
      } 
      to_index = @index.add(1, "monkey", "snakes", { 
        "foo" => :bar,
        "battles" => { 
          "often" => "sings like smurfs",
          "but" => "still has good records",
          "for" => [ "all", "of", "that" ]
        },
        "snoopy" => "sits_in_a_barn"
      })
      validate.each do |k, v|
        if v.kind_of?(Array)
          # Every entry in to_index[k] should be in v
          r = to_index[k] & v
          r.length.should == to_index[k].length
        else
          to_index[k].should == v
        end
      end
    end

    it "should send the document to solr" do
      @index.should_receive(:solr_add)
      @index.add(1, "monkey", "snakes", { "foo" => "bar" })
    end
  end

  describe "delete" do
    it "should delete by id" do
      @index.should_receive(:solr_delete_by_id).with(1)
      @index.delete(1)
    end
  end

  describe "delete_by_query" do
    it "should delete by query" do
      @index.should_receive(:solr_delete_by_query).with("foo:bar")
      @index.delete_by_query("foo:bar")
    end
  end

  describe "flatten_and_expand" do
    before(:each) do
      @fields = Hash.new
    end

    it "should set a value for the parent as key, with the key as the value" do
      @index.flatten_and_expand({ "one" => "woot" }, @fields, "omerta")
      @fields["omerta"].should == "one"
    end

    it "should call itself recursively for values that are hashes" do
      @index.flatten_and_expand({ "one" => { "two" => "three", "four" => { "five" => "six" } }}, @fields)
      {
        "one" => [ "two", "four" ],
        "one_two" => "three",
        "X_two" => "three",
        "two" => "three",
        "one_four" => "five",
        "X_four" => "five",
        "one_X" => [ "three", "five" ],
        "one_four_five" => "six", 
        "X_four_five" => "six",
        "one_X_five" => "six",
        "one_four_X" => "six",
        "five" => "six"
      }.each do |k, v|
        @fields[k].should == v
      end
    end

  end

  describe "set_field_value" do
    before(:each) do
      @fields = Hash.new
    end

    it "should set a value in the fields hash" do
      @index.set_field_value(@fields, "one", "two")
      @fields["one"].should eql("two")
    end

    it "should create an array of all values, if a field is set twice" do
      @index.set_field_value(@fields, "one", "two")
      @index.set_field_value(@fields, "one", "three")
      @fields["one"].should eql([ "two", "three" ])
    end

    it "should not add duplicate values to a field when there is one string entry" do
      @index.set_field_value(@fields, "one", "two")
      @index.set_field_value(@fields, "one", "two")
      @fields["one"].should eql("two")
    end

    it "should not add duplicate values to a field when it is an array" do
      @index.set_field_value(@fields, "one", "two")
      @index.set_field_value(@fields, "one", "three")
      @index.set_field_value(@fields, "one", "two")
      @fields["one"].should eql([ "two", "three" ])
    end

    it "should accept arrays as values" do
      @index.set_field_value(@fields, "one", [ "two", "three" ])
      @fields["one"].should eql([ "two", "three" ]) 
    end

    it "should not duplicate values when a field has been set with multiple arrays" do
      @index.set_field_value(@fields, "one", [ "two", "three" ])
      @index.set_field_value(@fields, "one", [ "two", "four" ])
      @fields["one"].should eql([ "two", "three", "four" ]) 
    end


    it "should allow you to set a value in the fields hash to an array" do
      @index.set_field_value(@fields, "one", [ "foo", "bar", "baz" ])
    end

    it "should not allow you to set a value in the fields hash to a hash" do
      lambda {
        @index.set_field_value(@fields, "one", { "two" => "three" })
      }.should raise_error(ArgumentError)
    end
  end
end
