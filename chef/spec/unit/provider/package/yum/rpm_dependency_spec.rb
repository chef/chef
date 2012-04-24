require 'spec_helper'

describe Chef::Provider::Package::Yum::RPMDependency do
  describe '#new' do
    context "with parsing" do
      before do
        @rpmdep = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==)
      end

      it "should expose name, version, flag available" do
        @rpmdep.name.should == "testing"
        @rpmdep.version.e.should == 1
        @rpmdep.version.v.should == "1.6.5"
        @rpmdep.version.r.should == "9.36.el5"
        @rpmdep.flag.should == :==
      end
    end

    context "without parsing" do
      before do
        @rpmdep = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1", "1.6.5", "9.36.el5", :==)
      end

      it "should expose name, version, flag available" do
        @rpmdep.name.should == "testing"
        @rpmdep.version.e.should == 1
        @rpmdep.version.v.should == "1.6.5"
        @rpmdep.version.r.should == "9.36.el5"
        @rpmdep.flag.should == :==
      end
    end

    it "should raise an error unless passed 3 or 5 args" do
      lambda {
        Chef::Provider::Package::Yum::RPMDependency.new()
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMDependency.new("testing")
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5")
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==)
      }.should_not raise_error
      lambda {
        Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==, "extra")
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMDependency.new("testing", "1", "1.6.5", "9.36.el5", :==)
      }.should_not raise_error
      lambda {
        Chef::Provider::Package::Yum::RPMDependency.new("testing", "1", "1.6.5", "9.36.el5", :==, "extra")
      }.should raise_error(ArgumentError)
    end
  end

  describe "#parse" do
    it "should parse a name, flag, version string into a valid RPMDependency object" do
      @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing >= 1:1.6.5-9.36.el5")

      @rpmdep.name.should == "testing"
      @rpmdep.version.e.should == 1
      @rpmdep.version.v.should == "1.6.5"
      @rpmdep.version.r.should == "9.36.el5"
      @rpmdep.flag.should == :>=
    end

    it "should parse a name into a valid RPMDependency object" do
      @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing")

      @rpmdep.name.should == "testing"
      @rpmdep.version.e.should == nil
      @rpmdep.version.v.should == nil
      @rpmdep.version.r.should == nil
      @rpmdep.flag.should == :==
    end

    it "should parse an invalid string into the name of a RPMDependency object" do
      @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing blah >")

      @rpmdep.name.should == "testing blah >"
      @rpmdep.version.e.should == nil
      @rpmdep.version.v.should == nil
      @rpmdep.version.r.should == nil
      @rpmdep.flag.should == :==
    end

    it "should parse various valid flags" do
      [
        [ ">", :> ],
        [ ">=", :>= ],
        [ "=", :== ],
        [ "==", :== ],
        [ "<=", :<= ],
        [ "<", :< ]
      ].each do |before, after|
        @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing #{before} 1:1.1-1")
        @rpmdep.flag.should == after
      end
    end

    it "should parse various invalid flags and treat them as names" do
      [
        [ "<>", :== ],
        [ "!=", :== ],
        [ ">>", :== ],
        [ "<<", :== ],
        [ "!", :== ],
        [ "~", :== ]
      ].each do |before, after|
        @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing #{before} 1:1.1-1")
        @rpmdep.name.should == "testing #{before} 1:1.1-1"
        @rpmdep.flag.should == after
      end
    end
  end

  describe "#satisfy?" do
    it "should raise an error unless a RPMDependency is passed" do
      @rpmprovide = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==)
      @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :>=)
      lambda {
        @rpmprovide.satisfy?("hi")
      }.should raise_error(ArgumentError)
      lambda {
        @rpmprovide.satisfy?(@rpmrequire)
      }.should_not raise_error
    end

    it "should validate dependency satisfaction logic for standard examples" do
      [
        # names
        [ "test", "test", true ],
        [ "test", "foo", false ],
        # full: epoch:version-relese
        [ "testing = 1:1.1-1", "testing > 1:1.1-0", true ],
        [ "testing = 1:1.1-1", "testing >= 1:1.1-0", true ],
        [ "testing = 1:1.1-1", "testing >= 1:1.1-1", true ],
        [ "testing = 1:1.1-1", "testing = 1:1.1-1", true ],
        [ "testing = 1:1.1-1", "testing == 1:1.1-1", true ],
        [ "testing = 1:1.1-1", "testing <= 1:1.1-1", true ],
        [ "testing = 1:1.1-1", "testing <= 1:1.1-0", false ],
        [ "testing = 1:1.1-1", "testing < 1:1.1-0", false ],
        # partial: epoch:version
        [ "testing = 1:1.1", "testing > 1:1.0", true ],
        [ "testing = 1:1.1", "testing >= 1:1.0", true ],
        [ "testing = 1:1.1", "testing >= 1:1.1", true ],
        [ "testing = 1:1.1", "testing = 1:1.1", true ],
        [ "testing = 1:1.1", "testing == 1:1.1", true ],
        [ "testing = 1:1.1", "testing <= 1:1.1", true ],
        [ "testing = 1:1.1", "testing <= 1:1.0", false ],
        [ "testing = 1:1.1", "testing < 1:1.0", false ],
        # partial: epoch
        [ "testing = 1:", "testing > 0:", true ],
        [ "testing = 1:", "testing >= 0:", true ],
        [ "testing = 1:", "testing >= 1:", true ],
        [ "testing = 1:", "testing = 1:", true ],
        [ "testing = 1:", "testing == 1:", true ],
        [ "testing = 1:", "testing <= 1:", true ],
        [ "testing = 1:", "testing <= 0:", false ],
        [ "testing = 1:", "testing < 0:", false ],
        # mix and match!
        [ "testing = 1:1.1-1", "testing == 1:1.1", true ],
        [ "testing = 1:1.1-1", "testing == 1:", true ],
     ].each do |prov, req, result|
        @rpmprovide = Chef::Provider::Package::Yum::RPMDependency.parse(prov)
        @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.parse(req)

        @rpmprovide.satisfy?(@rpmrequire).should == result
        @rpmrequire.satisfy?(@rpmprovide).should == result
      end
    end
  end

end
