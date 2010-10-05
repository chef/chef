require File.expand_path(File.join("#{File.dirname(__FILE__)}", '..', 'spec_helper'))
require 'net/http'

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

    describe "when the HTTP call is successful" do
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

    describe "when the HTTP call is unsuccessful" do
      [Timeout::Error, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EINVAL].each do |exception|
        it "should rescue, log an error message, and raise a SolrConnectionError encountering exception #{exception}" do
          lambda {
            @http.should_receive(:request).with(instance_of(Net::HTTP::Get)).and_raise(exception)
            Chef::Log.should_receive(:fatal).with(/Search Query to Solr '(.+?)' failed.  Chef::Exceptions::SolrConnectionError exception: #{exception}:.+/)
            @solr.solr_select("chef_opscode", "node", :q => "hostname:latte")
          }.should raise_error(Chef::Exceptions::SolrConnectionError)
        end
      end

      it "should rescue, log an error message, and raise a SolrConnectionError when encountering exception NoMethodError and net/http closed? bug" do
        lambda {
          @no_method_error = NoMethodError.new("undefined method 'closed\?' for nil:NilClass")
          @http.should_receive(:request).with(instance_of(Net::HTTP::Get)).and_raise(@no_method_error)
          Chef::Log.should_receive(:fatal).with(/Search Query to Solr '(.+?)' failed.  Chef::Exceptions::SolrConnectionError exception: Errno::ECONNREFUSED.+net\/http undefined method closed.+/)
          @solr.solr_select("chef_opscode", "node", :q => "hostname:latte")
        }.should raise_error(Chef::Exceptions::SolrConnectionError)
      end
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

    describe 'when the HTTP call is successful' do
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
        @solr.post_to_solr(:foo).should
      end
    end

    describe "when the HTTP call is unsuccessful due to an exception" do
      it "should post to /solr/update" do
        Net::HTTP::Post.should_receive(:new).with("/solr/update", "Content-Type" => "text/xml").and_return(@http_request)
        @solr.post_to_solr(@doc)
      end

      it "should set the body of the request to the stringified doc" do
        @http_request.should_receive(:body=).with("foo")
        @solr.post_to_solr(:foo)
      end

      [Timeout::Error, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EINVAL].each do |exception|
        it "should rescue and log an error message when encountering exception #{exception} and then re-raise it" do
          lambda {
            @http.should_receive(:request).with(@http_request).and_raise(exception)
            Chef::Log.should_receive(:fatal).with(/POST to Solr '(.+?)' failed.  Chef::Exceptions::SolrConnectionError exception: #{exception}:.+/)
            @solr.post_to_solr(:foo)
          }.should raise_error(Chef::Exceptions::SolrConnectionError)
        end
      end

      it "should rescue and log an error message when encountering exception NoMethodError and net/http closed? bug" do
        lambda {
          @no_method_error = NoMethodError.new("undefined method 'closed\?' for nil:NilClass")
          @http.should_receive(:request).with(@http_request).and_raise(@no_method_error)
          Chef::Log.should_receive(:fatal).with(/POST to Solr '(.+?)' failed.  Chef::Exceptions::SolrConnectionError exception: Errno::ECONNREFUSED.+net\/http undefined method closed.+/)
          @solr.post_to_solr(:foo)
        }.should raise_error(Chef::Exceptions::SolrConnectionError)
      end
    end
  end

  describe "solr_add" do
    before(:each) do
      @solr.stub!(:post_to_solr).and_return(true)
      @data = { "foo" => ["bar"] }
    end

    it "should send valid XML to solr" do
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<add><doc><field name=\"foo\">bar</field></doc></add>\n")
      @solr.solr_add(@data)
    end

    it "XML escapes content before sending to SOLR" do
      @data["foo"] = ["<&>"]
      @solr.should_receive(:post_to_solr).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<add><doc><field name=\"foo\">&lt;&amp;&gt;</field></doc></add>\n")

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
  
  describe "rebuilding the index" do
    before do
      Chef::Config[:couchdb_database] = "chunky_bacon"
    end
    
    it "deletes the index and commits" do
      @solr.should_receive(:solr_delete_by_query).with("X_CHEF_database_CHEF_X:chunky_bacon")
      @solr.should_receive(:solr_commit)
      @solr.stub!(:reindex_all)
      Chef::DataBag.stub!(:cdb_list).and_return([])
      @solr.rebuild_index
    end
    
    it "reindexes Chef::ApiClient, Chef::Node, and Chef::Role objects, reporting the results as a hash" do
      @solr.stub!(:solr_delete_by_query).with("X_CHEF_database_CHEF_X:chunky_bacon")
      @solr.stub!(:solr_commit)
      @solr.should_receive(:reindex_all).with(Chef::ApiClient).and_return(true)
      @solr.should_receive(:reindex_all).with(Chef::Node).and_return(true)
      @solr.should_receive(:reindex_all).with(Chef::Role).and_return(true)
      Chef::DataBag.stub!(:cdb_list).and_return([])
      
      result = @solr.rebuild_index
      result["Chef::ApiClient"].should == "success"
      result["Chef::Node"].should == "success"
      result["Chef::Role"].should == "success"
    end
    
    it "does not reindex Chef::OpenIDRegistration or Chef::WebUIUser objects" do
      # hi there. the reason we're specifying this behavior is because these objects
      # are not properly indexed in the first place and trying to reindex them
      # tickles a bug in our CamelCase to snake_case code. See CHEF-1009.
      @solr.stub!(:solr_delete_by_query).with("X_CHEF_database_CHEF_X:chunky_bacon")
      @solr.stub!(:solr_commit)
      @solr.stub!(:reindex_all).with(Chef::ApiClient)
      @solr.stub!(:reindex_all).with(Chef::Node)
      @solr.stub!(:reindex_all).with(Chef::Role)
      @solr.should_not_receive(:reindex_all).with(Chef::OpenIDRegistration)
      @solr.should_not_receive(:reindex_all).with(Chef::WebUIUser)
      Chef::DataBag.stub!(:cdb_list).and_return([])
      
      @solr.rebuild_index
    end
    
    it "reindexes databags" do
      one_data_item = Chef::DataBagItem.new
      one_data_item.raw_data = {"maybe"=>"snakes actually are evil", "id" => "just_sayin"}
      two_data_item = Chef::DataBagItem.new
      two_data_item.raw_data = {"tone_depth"=>"rumble_fish", "id" => "eff_yes"}
      data_bag = Chef::DataBag.new
      data_bag.stub!(:list).and_return([one_data_item, two_data_item])
      
      @solr.stub!(:solr_delete_by_query).with("X_CHEF_database_CHEF_X:chunky_bacon")
      @solr.stub!(:solr_commit)
      @solr.stub!(:reindex_all)
      Chef::DataBag.stub!(:cdb_list).and_return([data_bag])
      
      data_bag.should_receive(:add_to_index)
      one_data_item.should_receive(:add_to_index)
      two_data_item.should_receive(:add_to_index)
      
      @solr.rebuild_index["Chef::DataBag"].should == "success"
    end
  end
end
