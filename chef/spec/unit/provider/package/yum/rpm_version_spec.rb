require 'spec_helper'

describe Chef::Provider::Package::Yum::RPMVersion do
  describe "#new" do
    context 'with parsing' do
      before do
        @rpmv = Chef::Provider::Package::Yum::RPMVersion.new("1:1.6.5-9.36.el5")
      end

      it "should expose evr (name-version-release) available" do
        @rpmv.e.should == 1
        @rpmv.v.should == "1.6.5"
        @rpmv.r.should == "9.36.el5"

        @rpmv.evr.should == "1:1.6.5-9.36.el5"
      end

      it "should output a version-release string" do
        @rpmv.to_s.should == "1.6.5-9.36.el5"
      end
    end

    context "without parsing" do
      before do
        @rpmv = Chef::Provider::Package::Yum::RPMVersion.new("1", "1.6.5", "9.36.el5")
      end

      it "should expose evr (name-version-release) available" do
        @rpmv.e.should == 1
        @rpmv.v.should == "1.6.5"
        @rpmv.r.should == "9.36.el5"

        @rpmv.evr.should == "1:1.6.5-9.36.el5"
      end

      it "should output a version-release string" do
        @rpmv.to_s.should == "1.6.5-9.36.el5"
      end
    end

    it "should raise an error unless passed 1 or 3 args" do
      lambda {
        Chef::Provider::Package::Yum::RPMVersion.new()
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMVersion.new("1:1.6.5-9.36.el5")
      }.should_not raise_error
      lambda {
        Chef::Provider::Package::Yum::RPMVersion.new("1:1.6.5-9.36.el5", "extra")
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMVersion.new("1", "1.6.5", "9.36.el5")
      }.should_not raise_error
      lambda {
        Chef::Provider::Package::Yum::RPMVersion.new("1", "1.6.5", "9.36.el5", "extra")
      }.should raise_error(ArgumentError)
    end
  end

  # thanks version_class_spec.rb!
  describe "#compare" do
    it "should sort based on complete epoch-version-release data" do
      [
        # smaller, larger
        [ "0:1.6.5-9.36.el5",
          "1:1.6.5-9.36.el5" ],
        [ "0:2.3-15.el5",
          "0:3.3-15.el5" ],
        [ "0:alpha9.8-27.2",
          "0:beta9.8-27.2" ],
        [ "0:0.09-14jpp.3",
          "0:0.09-15jpp.3" ],
        [ "0:0.9.0-0.6.20110211.el5",
          "0:0.9.0-0.6.20120211.el5" ],
        [ "0:1.9.1-4.el5",
          "0:1.9.1-5.el5" ],
        [ "0:1.4.10-7.20090624svn.el5",
          "0:1.4.10-7.20090625svn.el5" ],
        [ "0:2.3.4-2.el5",
          "0:2.3.4-2.el6" ]
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should sort based on partial epoch-version-release data" do
      [
        # smaller, larger
        [ ":1.6.5-9.36.el5",
          "1:1.6.5-9.36.el5" ],
        [ "2.3-15.el5",
          "3.3-15.el5" ],
        [ "alpha9.8",
          "beta9.8" ],
        [ "14jpp",
          "15jpp" ],
        [ "0.9.0-0.6",
          "0.9.0-0.7" ],
        [ "0:1.9",
          "3:1.9" ],
        [ "2.3-2.el5",
          "2.3-2.el6" ]
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should verify equality of complete epoch-version-release data" do
      [
        [ "0:1.6.5-9.36.el5",
          "0:1.6.5-9.36.el5" ],
        [ "0:2.3-15.el5",
          "0:2.3-15.el5" ],
        [ "0:alpha9.8-27.2",
          "0:alpha9.8-27.2" ]
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        sm.should be == lg
      end
    end

    it "should verify equality of partial epoch-version-release data" do
      [
        [ ":1.6.5-9.36.el5",
          "0:1.6.5-9.36.el5" ],
        [ "2.3-15.el5",
          "2.3-15.el5" ],
        [ "alpha9.8-3",
          "alpha9.8-3" ]
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        sm.should be == lg
      end
    end
  end

  describe "#partial_compare" do
    it "should compare based on partial epoch-version-release data" do
      [
        # smaller, larger
        [ "0:1.1.1-1",
          "1:" ],
        [ "0:1.1.1-1",
          "0:1.1.2" ],
        [ "0:1.1.1-1",
          "0:1.1.2-1" ],
        [ "0:",
          "1:1.1.1-1" ],
        [ "0:1.1.1",
          "0:1.1.2-1" ],
        [ "0:1.1.1-1",
          "0:1.1.2-1" ],
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        sm.partial_compare(lg).should be == -1
        lg.partial_compare(sm).should be == 1
        sm.partial_compare(lg).should_not be == 0
      end
    end

    it "should verify equality based on partial epoch-version-release data" do
      [
        [ "0:",
          "0:1.1.1-1" ],
        [ "0:1.1.1",
          "0:1.1.1-1" ],
        [ "0:1.1.1-1",
          "0:1.1.1-1" ],
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        sm.partial_compare(lg).should be == 0
      end
    end
  end

end
