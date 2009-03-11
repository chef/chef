require File.dirname(__FILE__) + '/spec_helper'

describe "ChefServerSlice (module)" do
  
#   Implement your ChefServerSlice specs here
  
#   To spec ChefServerSlice you need to hook it up to the router like this:
  
  before :all do
    Merb::Router.prepare { add_slice(:ChefServerSlice) } if standalone?
  end
  
  after :all do
    Merb::Router.reset! if standalone?
  end
  
  
  it "should have proper specs"
  
end
