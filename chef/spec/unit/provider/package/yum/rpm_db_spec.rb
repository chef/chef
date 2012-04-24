require 'spec_helper'

# thanks resource_collection_spec.rb!
describe Chef::Provider::Package::Yum::RPMDb do
  before(:each) do
    @rpmdb = Chef::Provider::Package::Yum::RPMDb.new
    # name, version, arch, installed, available
    deps_v = [
      Chef::Provider::Package::Yum::RPMDependency.parse("libz.so.1()(64bit)"),
      Chef::Provider::Package::Yum::RPMDependency.parse("test-package-a = 0:1.6.5-9.36.el5")
    ]
    deps_z = [
      Chef::Provider::Package::Yum::RPMDependency.parse("libz.so.1()(64bit)"),
      Chef::Provider::Package::Yum::RPMDependency.parse("config(test) = 0:1.6.5-9.36.el5"),
      Chef::Provider::Package::Yum::RPMDependency.parse("test-package-c = 0:1.6.5-9.36.el5")
    ]
    @rpm_v = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-a", "0:1.6.5-9.36.el5", "i386", deps_v, true, false, "base")
    @rpm_w = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "i386", [], true, true, "extras")
    @rpm_x = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "x86_64", [], false, true, "extras")
    @rpm_y = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "1:1.6.5-9.36.el5", "x86_64", [], true, true, "extras")
    @rpm_z = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-c", "0:1.6.5-9.36.el5", "noarch", deps_z, true, true, "base")
    @rpm_z_mirror = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-c", "0:1.6.5-9.36.el5", "noarch", deps_z, true, true, "base")
  end

  describe "#new" do
    it "should return a Chef::Provider::Package::Yum::RPMDb object" do
      @rpmdb.should be_kind_of(Chef::Provider::Package::Yum::RPMDb)
    end
  end

  describe "#push" do
    it "should accept an RPMDbPackage object through pushing" do
      lambda { @rpmdb.push(@rpm_w) }.should_not raise_error
    end

    it "should accept multiple RPMDbPackage object through pushing" do
      lambda { @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z) }.should_not raise_error
    end

    it "should only accept an RPMDbPackage object" do
      lambda { @rpmdb.push("string") }.should raise_error
    end

    it "should add the package to the package db" do
      @rpmdb.push(@rpm_w)
      @rpmdb["test-package-b"].should_not be == nil
    end

    it "should add conditionally add the package to the available list" do
      @rpmdb.available_size.should be == 0
      @rpmdb.push(@rpm_v, @rpm_w)
      @rpmdb.available_size.should be == 1
    end

    it "should add conditionally add the package to the installed list" do
      @rpmdb.installed_size.should be == 0
      @rpmdb.push(@rpm_w, @rpm_x)
      @rpmdb.installed_size.should be == 1
    end

    it "should have a total of 2 packages in the RPMDb" do
      @rpmdb.size.should be == 0
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb.size.should be == 2
    end

    it "should keep the Array unique when a duplicate is pushed" do
      @rpmdb.push(@rpm_z, @rpm_z_mirror)
      @rpmdb["test-package-c"].size.should be == 1
    end

    it "should register the package provides in the provides index" do
      @rpmdb.push(@rpm_v, @rpm_w, @rpm_z)
      @rpmdb.lookup_provides("test-package-a")[0].should be == @rpm_v
      @rpmdb.lookup_provides("config(test)")[0].should be == @rpm_z
      @rpmdb.lookup_provides("libz.so.1()(64bit)")[0].should be == @rpm_v
      @rpmdb.lookup_provides("libz.so.1()(64bit)")[1].should be == @rpm_z
    end
  end

  describe "#<<" do
    it "should accept an RPMPackage object through the << operator" do
      lambda { @rpmdb << @rpm_w }.should_not raise_error
    end
  end

  describe "#lookup" do
    it "should return an Array of RPMPackage objects by index" do
      @rpmdb << @rpm_w
      @rpmdb.lookup("test-package-b").should be_kind_of(Array)
    end
  end

  describe "#[]" do
    it "should return an Array of RPMPackage objects though the [index] operator" do
      @rpmdb << @rpm_w
      @rpmdb["test-package-b"].should be_kind_of(Array)
    end

    it "should return an Array of 3 RPMPackage objects" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb["test-package-b"].size.should be == 3
    end

    it "should return an Array of RPMPackage objects sorted from newest to oldest" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb["test-package-b"][0].should be == @rpm_y
      @rpmdb["test-package-b"][1].should be == @rpm_x
      @rpmdb["test-package-b"][2].should be == @rpm_w
    end
  end

  describe "#lookup_provides" do
    it "should return an Array of RPMPackage objects by index" do
      @rpmdb << @rpm_z
      x = @rpmdb.lookup_provides("config(test)")
      x.should be_kind_of(Array)
      x[0].should be == @rpm_z
    end
  end

  describe "#clear" do
    it "should clear the RPMDb" do
      @rpmdb.should_receive(:clear_available).once
      @rpmdb.should_receive(:clear_installed).once
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb.size.should_not be == 0
      @rpmdb.lookup_provides("config(test)").should be_kind_of(Array)
      @rpmdb.clear
      @rpmdb.lookup_provides("config(test)").should be == nil
      @rpmdb.size.should be == 0
    end
  end

  describe "#clear_available" do
    it "should clear the available list" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb.available_size.should_not be == 0
      @rpmdb.clear_available
      @rpmdb.available_size.should be == 0
    end
  end

  describe "#available?" do
    it "should return true if a package is available" do
      @rpmdb.available?(@rpm_w).should be == false
      @rpmdb.push(@rpm_v, @rpm_w)
      @rpmdb.available?(@rpm_v).should be == false
      @rpmdb.available?(@rpm_w).should be == true
    end
  end

  describe "#clear_installed" do
    it "should clear the installed list" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb.installed_size.should_not be == 0
      @rpmdb.clear_installed
      @rpmdb.installed_size.should be == 0
    end
  end

  describe "#installed?" do
    it "should return true if a package is installed" do
      @rpmdb.installed?(@rpm_w).should be == false
      @rpmdb.push(@rpm_w, @rpm_x)
      @rpmdb.installed?(@rpm_w).should be == true
      @rpmdb.installed?(@rpm_x).should be == false
    end
  end

  describe "#whatprovides" do
    it "should raise an error unless a RPMDependency is passed" do
      @rpmprovide = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==)
      @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :>=)
      lambda {
        @rpmdb.whatprovides("hi")
      }.should raise_error(ArgumentError)
      lambda {
        @rpmdb.whatprovides(@rpmrequire)
      }.should_not raise_error
    end

    it "should return an Array of packages statisfying a RPMDependency" do
      @rpmdb.push(@rpm_v, @rpm_w, @rpm_z)

      @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.parse("test-package-a >= 1.6.5")
      x = @rpmdb.whatprovides(@rpmrequire)
      x.should be_kind_of(Array)
      x[0].should be == @rpm_v

      @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.parse("libz.so.1()(64bit)")
      x = @rpmdb.whatprovides(@rpmrequire)
      x.should be_kind_of(Array)
      x[0].should be == @rpm_v
      x[1].should be == @rpm_z
    end
  end

end
