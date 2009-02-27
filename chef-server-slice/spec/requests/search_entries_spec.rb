require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/search_entries" do
  before(:each) do
    @response = request("/search_entries")
  end
end