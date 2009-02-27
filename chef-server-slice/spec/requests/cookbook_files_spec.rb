require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/cookbook_files" do
  before(:each) do
    @response = request("/cookbook_files")
  end
end