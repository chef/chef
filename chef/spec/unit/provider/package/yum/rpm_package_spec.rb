require 'spec_helper'

describe Chef::Provider::Package::Yum::RPMPackage do
  describe '#new' do
    context "with parsing" do
      before do
        @rpm = Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64", [])
      end

      it "should expose nevra (name-epoch-version-release-arch) available" do
        @rpm.name.should == "testing"
        @rpm.version.e.should == 1
        @rpm.version.v.should == "1.6.5"
        @rpm.version.r.should == "9.36.el5"
        @rpm.arch.should == "x86_64"

        @rpm.nevra.should == "testing-1:1.6.5-9.36.el5.x86_64"
        @rpm.to_s.should == @rpm.nevra
      end

      it "should always have at least one provide, itself" do
        @rpm.provides.size.should == 1
        @rpm.provides[0].name == "testing"
        @rpm.provides[0].version.evr == "1:1.6.5-9.36.el5"
        @rpm.provides[0].flag == :==
      end
    end

    describe "without parsing" do
      before do
        @rpm = Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64", [])
      end

      it "should expose nevra (name-epoch-version-release-arch) available" do
        @rpm.name.should == "testing"
        @rpm.version.e.should == 1
        @rpm.version.v.should == "1.6.5"
        @rpm.version.r.should == "9.36.el5"
        @rpm.arch.should == "x86_64"

        @rpm.nevra.should == "testing-1:1.6.5-9.36.el5.x86_64"
        @rpm.to_s.should == @rpm.nevra
      end

      it "should always have at least one provide, itself" do
        @rpm.provides.size.should == 1
        @rpm.provides[0].name == "testing"
        @rpm.provides[0].version.evr == "1:1.6.5-9.36.el5"
        @rpm.provides[0].flag == :==
      end
    end

    it "should raise an error unless passed 4 or 6 args" do
      lambda {
        Chef::Provider::Package::Yum::RPMPackage.new()
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMPackage.new("testing")
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5")
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64")
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64", [])
      }.should_not raise_error
      lambda {
        Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64")
      }.should raise_error(ArgumentError)
      lambda {
        Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64", [])
      }.should_not raise_error
      lambda {
        Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64", [], "extra")
      }.should raise_error(ArgumentError)
    end
  end

  describe "#<=>" do
    it "should sort alphabetically based on package name" do
      [
        [ "a-test",
          "b-test" ],
        [ "B-test",
          "a-test" ],
        [ "A-test",
          "B-test" ],
        [ "Aa-test",
          "aA-test" ],
        [ "1test",
          "2test" ],
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMPackage.new(smaller, "0:0.0.1-1", "x86_64", [])
        lg = Chef::Provider::Package::Yum::RPMPackage.new(larger, "0:0.0.1-1", "x86_64", [])
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should sort alphabetically based on package arch" do
      [
        [ "i386",
          "x86_64" ],
        [ "i386",
          "noarch" ],
        [ "noarch",
          "x86_64" ],
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMPackage.new("test-package", "0:0.0.1-1", smaller, [])
        lg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", "0:0.0.1-1", larger, [])
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end
  end
end

describe Chef::Provider::Package::Yum::RPMDbPackage do
  before(:each) do
    # name, version, arch, installed, available, repoid
    @rpm_x = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", [], false, true, "base")
    @rpm_y = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", [], true, true, "extras")
    @rpm_z = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", [], true, false, "other")
  end

  describe "#new" do
    it "should return a Chef::Provider::Package::Yum::RPMDbPackage object" do
      @rpm_x.should be_kind_of(Chef::Provider::Package::Yum::RPMDbPackage)
    end
  end

  describe "#available" do
    it "should return true" do
      @rpm_x.available.should be == true
      @rpm_y.available.should be == true
      @rpm_z.available.should be == false
    end
  end

  describe "#installed" do
    it "should return true" do
      @rpm_x.installed.should be == false
      @rpm_y.installed.should be == true
      @rpm_z.installed.should be == true
    end
  end

  describe "#repoid" do
    it "should return the source repository repoid" do
      @rpm_x.repoid.should be == "base" 
      @rpm_y.repoid.should be == "extras"
      @rpm_z.repoid.should be == "other"
    end
  end
end
