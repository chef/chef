require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/cookbook_templates" do
  before(:each) do
    @response = request("/cookbook_templates")
  end
end