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
        "X_CHEF_id_CHEF_X" => [1],
        "X_CHEF_database_CHEF_X" => ["monkey"],
        "X_CHEF_type_CHEF_X" => ["snakes"],
        "foo" => ["bar"],
        "battles" => [ "often", "but", "for" ],
        "battles_often" => ["sings like smurfs"],
        "often" => ["sings like smurfs"],
        "battles_but" => ["still has good records"],
        "but" => ["still has good records"],
        "battles_for" => [ "all", "of", "that" ],
        "for" => [ "all", "of", "that" ],
        "snoopy" => ["sits-in-a-barn"],
        "battles_X" => [ "sings like smurfs", "still has good records", "all", "of", "that" ],
        "X_often" =>[ "sings like smurfs"],
        "X_but" => ["still has good records"],
        "X_for" => [ "all", "of", "that" ]
      }
      to_index = @index.add(1, "monkey", "snakes", {
        "foo" => :bar,
        "battles" => {
          "often" => "sings like smurfs",
          "but" => "still has good records",
          "for" => [ "all", "of", "that" ]
        },
        "snoopy" => "sits-in-a-barn"
      })

      validate.each do |k, v|
        if v.kind_of?(Array)
          to_index[k].sort.should == v.sort
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
      @fields = @index.flatten_and_expand("omerta" => { "one" => "woot" })
      @fields["omerta"].should == ["one"]
    end

    it "should call itself recursively for values that are hashes" do
      @fields = @index.flatten_and_expand({ "one" => { "two" => "three", "four" => { "five" => "six" } }})
      expected = {"one" => [ "two", "four" ],
                  "one_two" => ["three"],
                  "X_two" => ["three"],
                  "two" => ["three"],
                  "one_four" => ["five"],
                  "X_four" => ["five"],
                  "one_X" => [ "three", "five" ],
                  "one_four_five" => ["six"],
                  "X_four_five" => ["six"],
                  "one_X_five" => ["six"],
                  "one_four_X" => ["six"],
                  "five" => ["six"]}
      expected.each do |k, v|
        @fields[k].should == v
      end
    end

    it "should call itself recursively for hashes nested in arrays" do
      @fields = @index.flatten_and_expand({ :one => [ { :two => "three" }, { :four => { :five => "six" } } ] })
      expected = {"one_X_five" => ["six"],
                  "one_four" => ["five"],
                  "one_X" => [ "three", "five" ],
                  "two" => ["three"],
                  "one_four_X" => ["six"],
                  "X_four" => ["five"],
                  "X_four_five" => ["six"],
                  "one" => [ "two", "four" ],
                  "one_four_five" => ["six"],
                  "five" => ["six"],
                  "X_two" => ["three"],
                  "one_two" => ["three"]}

      expected.each do |key, expected_value|
        @fields[key].should == expected_value
      end
    end

    it "generates unlimited levels of expando fields when expanding" do
      expected_keys = ["one",
                       "one_two",
                       "X_two",
                       "one_X",
                       "one_two_three",
                       "X_two_three",
                       "one_X_three",
                       "one_two_X",
                       "one_two_three_four",
                       "X_two_three_four",
                       "one_X_three_four",
                       "one_two_X_four",
                       "one_two_three_X",
                       "one_two_three_four_five",
                       "X_two_three_four_five",
                       "one_X_three_four_five",
                       "one_two_X_four_five",
                       "one_two_three_X_five",
                       "one_two_three_four_X",
                       "six",
                       "one_two_three_four_five_six",
                       "X_two_three_four_five_six",
                       "one_X_three_four_five_six",
                       "one_two_X_four_five_six",
                       "one_two_three_X_five_six",
                       "one_two_three_four_X_six",
                       "one_two_three_four_five_X"].sort

      nested = {:one => {:two => {:three => {:four => {:five => {:six => :end}}}}}}
      @fields = @index.flatten_and_expand(nested)

      @fields.keys.sort.should include(*expected_keys)
    end

  end

  describe "creating expando fields" do
    def make_expando_fields(parts)
      expando_fields = []
      @index.each_expando_field(parts) { |ex| expando_fields << ex }
      expando_fields
    end

    it "joins the fields with a big X" do
      make_expando_fields(%w{foo bar baz qux}).should == ["X_bar_baz_qux", "foo_X_baz_qux", "foo_bar_X_qux", "foo_bar_baz_X"]
      make_expando_fields(%w{foo bar baz}).should == ["X_bar_baz", "foo_X_baz", "foo_bar_X"]
      make_expando_fields(%w{foo bar}).should == ["X_bar", "foo_X"]
      make_expando_fields(%w{foo}).should == []
    end
  end

end
