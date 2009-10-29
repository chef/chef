require File.expand_path(File.join("#{File.dirname(__FILE__)}", '..', 'spec_helper'))

describe Chef::Solr do
  before(:each) do 
    @solr = Chef::Solr.new
  end

  describe "initialize" do
    it "should create a new Chef::Solr object" do
      @solr.should be_a_kind_of(Chef::Solr)
    end

    it "should accept an alternate solr url" do
      solr = Chef::Solr.new("http://example.com")
      solr.solr_url.should eql("http://example.com")
    end
  end

  describe "solr_select" do
    before(:each) do
      @http_response = mock(
        "Net::HTTP::Response", 
        :kind_of? => Net::HTTPSuccess,
        :body => "{ :some => :hash }"
      )
      @http = mock("Net::HTTP", :request => @http_response)
      @solr.http = @http
    end

    it "should call get to /solr/select with the escaped query" do
      Net::HTTP::Get.should_receive(:new).with(%r(q=hostname%3Alatte))
      @solr.solr_select("chef_opscode", "node", :q => "hostname:latte")
    end

    it "should call get to /solr/select with wt=ruby" do
      Net::HTTP::Get.should_receive(:new).with(%r(wt=ruby))
      @solr.solr_select("chef_opscode", "node", :q => "hostname:latte")
    end

    it "should call get to /solr/select with indent=off" do
      Net::HTTP::Get.should_receive(:new).with(%r(indent=off))
      @solr.solr_select("chef_opscode", "node", :q => "hostname:latte")
    end
     
    it "should call get to /solr/select with filter query" do
      Net::HTTP::Get.should_receive(:new).with(/fq=%2BX_CHEF_database_CHEF_X%3Achef_opscode\+%2BX_CHEF_type_CHEF_X%3Anode/)
      @solr.solr_select("chef_opscode", "node", :q => "hostname:latte")
    end

    it "should return the evaluated response body" do
      res = @solr.solr_select("chef_opscode", "node", :q => "hostname:latte")
      res.should == { :some => :hash }
    end
  end


  describe "post_to_solr" do
    before(:each) do
      @http_response = mock(
        "Net::HTTP::Response", 
        :kind_of? => Net::HTTPSuccess,
        :body => "{ :some => :hash }"
      )
      @http_request = mock(
        "Net::HTTP::Request",
        :body= => true
      )
      @http = mock("Net::HTTP", :request => @http_response)
      @solr.http = @http
      Net::HTTP::Post.stub!(:new).and_return(@http_request)
      @doc = { "foo" => "bar" }
    end
  
    it "should post to /solr/update" do
      Net::HTTP::Post.should_receive(:new).with("/solr/update", "Content-Type" => "text/xml").and_return(@http_request)
      @solr.post_to_solr(@doc)
    end

    it "should set the body of the request to the stringified doc" do
      @http_request.should_receive(:body=).with("foo")
      @solr.post_to_solr(:foo)
    end

    it "should send the request to solr" do
      @http.should_receive(:request).with(@http_request).and_return(@http_response)
      @solr.post_to_solr(:foo)
    end
  end

  describe "solr_add" do
    before(:each) do
      @solr.stub!(:post_to_solr).and_return(true)
      @data = { "foo" => "bar" }
    end

    it "should send valid XML to solr" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<add><doc><field name=\"foo\">bar</field></doc></add>\n")
      @solr.solr_add(@data)
    end
  end

  describe "solr_commit" do
    before(:each) do
      @solr.stub!(:post_to_solr).and_return(true)
    end

    it "should send valid commit xml to solr" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<commit/>\n")
      @solr.solr_commit
    end
  end

  describe "solr_optimize" do
    before(:each) do
      @solr.stub!(:post_to_solr).and_return(true)
    end

    it "should send valid commit xml to solr" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<optimize/>\n")
      @solr.solr_optimize
    end
  end

  describe "solr_rollback" do
    before(:each) do
      @solr.stub!(:post_to_solr).and_return(true)
    end

    it "should send valid commit xml to solr" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rollback/>\n")
      @solr.solr_rollback
    end
  end

  describe "solr_delete_by_id" do
    before(:each) do
      @solr.stub!(:post_to_solr).and_return(true)
    end

    it "should send valid delete id xml to solr" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<delete><id>1</id></delete>\n")
      @solr.solr_delete_by_id(1)
    end

    it "should accept multiple ids" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<delete><id>1</id><id>2</id></delete>\n")
      @solr.solr_delete_by_id([ 1, 2 ])
    end
  end

  describe "solr_delete_by_query" do
    before(:each) do
      @solr.stub!(:post_to_solr).and_return(true)
    end

    it "should send valid delete id xml to solr" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<delete><query>foo:bar</query></delete>\n")
      @solr.solr_delete_by_query("foo:bar")
    end

    it "should accept multiple ids" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<delete><query>foo:bar</query><query>baz:bum</query></delete>\n")
      @solr.solr_delete_by_query([ "foo:bar", "baz:bum" ])
    end
  end

end
