require File.expand_path(File.join("#{File.dirname(__FILE__)}", '..', 'spec_helper'))

require 'chef/solr_query'
require 'net/http'

describe Chef::SolrQuery do
  before(:all) do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://example.com:8983"

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
    Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
    Net::HTTP::Post.stub!(:new).and_return(@http_request)
    Net::HTTP::Get.stub!(:new).and_return(@http_request)
    @doc = { "foo" => "bar" }
  end

  before(:each) do 
    @solr = Chef::SolrQuery.new
  end

  it "sets filter query params" do
    @solr.filter_by(:database => 'chef')
    @solr.filter_query.should == "+X_CHEF_database_CHEF_X:chef"
  end

  it "filters by type when querying for a builtin type" do
    @solr.filter_by_type("node")
    @solr.filter_query.should == "+X_CHEF_type_CHEF_X:node"
  end

  it "filters by type for data bag items" do
    @solr.filter_by_type("users")
    @solr.filter_query.should == '+X_CHEF_type_CHEF_X:data_bag +data_bag:users'
  end

  it "stores the main query" do
    @solr.query = "role:prod AND tags:chef-server"
    @solr.query.should == "role:prod AND tags:chef-server"
  end

  describe "when executing a query" do
    before(:each) do
      @http_response = mock(
        "Net::HTTP::Response", 
        :kind_of? => Net::HTTPSuccess,
        :body => '{"some": "hash" }'
      )
      @solr.update_filter_query_from_params(:type => 'node')
      @solr.query = "hostname:latte"
      @http = mock("Net::HTTP", :request => @http_response)
      #@solr.http = @http
      Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
    end

    describe "when the HTTP call is successful" do
      it "should call get to /solr/select with the escaped query" do
        Net::HTTP::Get.should_receive(:new).with(%r(q=hostname%3Alatte))
        @solr.solr_select
      end

      it "uses Solr's JSON response format" do
        Net::HTTP::Get.should_receive(:new).with(%r(wt=json))
        @solr.solr_select
      end

      it "uses indent=off to get a compact response" do
        Net::HTTP::Get.should_receive(:new).with(%r(indent=off))
        @solr.solr_select
      end

      it "uses the filter query to restrict the result set" do
        filter_query =@solr.filter_query.gsub('+', '%2B').gsub(':', "%3A").gsub(' ', '+')
        Net::HTTP::Get.should_receive(:new).with(/fq=#{Regexp.escape(filter_query)}/)
        @solr.solr_select
      end

      it "returns the evaluated response body" do
        res = @solr.solr_select
        res.should == {"some" => "hash" }
      end

      it "defaults to returning 1000 rows" do
        @solr.select_url_from({}).should match(/rows=1000/)
      end

      it "returns the number of rows requested" do
        @solr.select_url_from({:rows => 500}).should match(/rows=500/)
      end

      it "offsets the row selection if requested" do
        @solr.select_url_from(:start => 500).should match(/start=500/)
      end

    end

  end

  describe "when POSTing an update" do
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
      Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
      Net::HTTP::Post.stub!(:new).and_return(@http_request)
      @doc = { "foo" => "bar" }
    end

    describe 'when the HTTP call is successful' do

    end

  end

  describe "when forcing a Solr commit" do
    it "sends valid commit xml to solr" do
      Chef::SolrQuery::SolrHTTPRequest.should_receive(:update).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<commit/>\n")
      @solr.commit
    end
  end

  describe "when deleting a database from Solr" do
    it "sends a valid delete query to solr and forces a commit" do
      Chef::SolrQuery::SolrHTTPRequest.should_receive(:update).with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<delete><query>X_CHEF_database_CHEF_X:chef</query></delete>\n")
      @solr.should_receive(:commit)
      @solr.delete_database("chef")
    end
  end
  
  describe "rebuilding the index" do
    before do
      Chef::Config[:couchdb_database] = "chunky_bacon"
    end
    
    it "deletes the index and commits" do
      @solr.should_receive(:delete_database).with("chunky_bacon")
      @solr.stub!(:reindex_all)
      Chef::DataBag.stub!(:cdb_list).and_return([])
      @solr.rebuild_index
    end
    
    it "reindexes Chef::ApiClient, Chef::Node, and Chef::Role objects, reporting the results as a hash" do
      @solr.should_receive(:delete_database).with("chunky_bacon")
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
      @solr.should_receive(:delete_database).with("chunky_bacon")
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
      
      @solr.should_receive(:delete_database).with("chunky_bacon")
      @solr.stub!(:reindex_all)
      Chef::DataBag.stub!(:cdb_list).and_return([data_bag])
      
      data_bag.should_receive(:add_to_index)
      one_data_item.should_receive(:add_to_index)
      two_data_item.should_receive(:add_to_index)
      
      @solr.rebuild_index["Chef::DataBag"].should == "success"
    end
  end

  describe "when transforming queries to match to support backwards compatibility with the old solr schema" do
    before(:each) do
      @query = Chef::SolrQuery.new
    end

    it "should transform queries correctly" do
      testcases = Hash[*(File.readlines("#{CHEF_SPEC_DATA}/search_queries_to_transform.txt").select{|line| line !~ /^\s*$/}.map{|line| line.chomp})]
      testcases.each do |input, expected|
        @query.transform_search_query(input).should == expected
      end
    end
    
  end

end

describe Chef::SolrQuery::SolrHTTPRequest do
  before do
    Chef::Config[:solr_url] = "http://example.com:8983"
    Chef::SolrQuery::SolrHTTPRequest.instance_variable_set(:@solr_url, nil)

    @request = Chef::SolrQuery::SolrHTTPRequest.new(:GET, '/solr/select')
  end

  it "defaults to using the configured solr_url" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url.should == "http://example.com:8983"
  end

  it "updates the Solr URL as you like" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234"
    Chef::SolrQuery::SolrHTTPRequest.solr_url.should == "http://chunkybacon.org:1234"
  end

  it "creates a Net::HTTP client for the base Solr URL" do
    Chef::SolrQuery::SolrHTTPRequest.solr_url = "http://chunkybacon.org:1234"
    http_client = Chef::SolrQuery::SolrHTTPRequest.http_client
    http_client.address.should == "chunkybacon.org"
    http_client.port.should == 1234
  end

  describe "when configured with the Solr URL" do
    before do
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
      Chef::SolrQuery::SolrHTTPRequest.stub!(:http_client).and_return(@http)
    end

    describe "when updating" do
      before do
        Net::HTTP::Post.stub!(:new).and_return(@http_request)
      end

      it "should post to /solr/update" do
        @doc = "<xml is the old tldr>"
        Net::HTTP::Post.should_receive(:new).with("/solr/update", "Content-Type" => "text/xml").and_return(@http_request)
        Chef::SolrQuery::SolrHTTPRequest.update(@doc)
      end

      it "should set the body of the request to the stringified doc" do
        @http_request.should_receive(:body=).with("foo")
        Chef::SolrQuery::SolrHTTPRequest.update(:foo)
      end

      it "should send the request to solr" do
        @http.should_receive(:request).with(@http_request).and_return(@http_response)
        Chef::SolrQuery::SolrHTTPRequest.update(:foo)
      end

    end

    describe "when the HTTP call is unsuccessful" do
      [Timeout::Error, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EINVAL].each do |exception|
        it "should rescue, log an error message, and raise a SolrConnectionError encountering exception #{exception}" do
          response = mock("Net:HTTPResponse test double", :code => 500, :message => "oops", :class => exception)
          @http.should_receive(:request).with(instance_of(Net::HTTP::Get)).and_return(response)
          response.should_receive(:error!).and_raise(exception)
          Chef::Log.should_receive(:fatal).with("Search Query to Solr failed (#{exception} 500 oops)")

          lambda {@request.run('Search Query to Solr')}.should raise_error(Chef::Exceptions::SolrConnectionError)
        end
      end

      it "should rescue, log an error message, and raise a SolrConnectionError when encountering exception NoMethodError and net/http closed? bug" do
        @no_method_error = NoMethodError.new("undefined method 'closed\?' for nil:NilClass")
        @http.should_receive(:request).with(instance_of(Net::HTTP::Get)).and_raise(@no_method_error)
        Chef::Log.should_receive(:fatal).with("HTTP Request to Solr failed.  Chef::Exceptions::SolrConnectionError exception: Errno::ECONNREFUSED (net/http undefined method closed?) attempting to contact http://example.com:8983")
        lambda {
          @request.run
        }.should raise_error(Chef::Exceptions::SolrConnectionError)
      end
    end
    
  end
end
