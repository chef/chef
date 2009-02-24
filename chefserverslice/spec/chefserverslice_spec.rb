require File.dirname(__FILE__) + '/spec_helper'

describe "Chefserverslice (module)" do
  
#   Implement your Chefserverslice specs here
  
#   To spec Chefserverslice you need to hook it up to the router like this:
  
  before :all do
    Merb::Router.prepare { add_slice(:Chefserverslice) } if standalone?
  end
  
  after :all do
    Merb::Router.reset! if standalone?
  end
  
  
  it "should have proper specs"
  
end
