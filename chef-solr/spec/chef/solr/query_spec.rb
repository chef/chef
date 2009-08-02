require File.expand_path(File.join("#{File.dirname(__FILE__)}", '..', '..', 'spec_helper'))

describe Chef::Solr::Query do
  before(:each) do
    @query = Chef::Solr::Query.new
  end

  describe "initialize" do
    it "should return a Chef::Solr::Query" do
      @query.should be_a_kind_of(Chef::Solr::Query)
    end
  end
end

