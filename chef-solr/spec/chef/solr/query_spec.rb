require File.expand_path(File.join("#{File.dirname(__FILE__)}", '..', '..', 'spec_helper'))

describe Chef::Solr::Query do
  before(:each) do
    @query = Chef::Solr::Query.new
  end

  it "should transform queries correctly" do
    testcases = Hash[*(File.readlines("#{CHEF_SOLR_SPEC_DATA}/search_queries_to_transform.txt").select{|line| line !~ /^\s*$/}.map{|line| line.chomp})]
    testcases.each do |input, expected|
      @query.transform_search_query(input).should == expected
    end
  end

end

