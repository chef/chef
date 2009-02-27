require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/cookbook_recipes" do
  before(:each) do
    @response = request("/cookbook_recipes")
  end
end