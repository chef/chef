require 'spec_helper'

describe Chef::Provider::Package::Yum::YumCache do
  # allow for the reset of a Singleton
  # thanks to Ian White (http://blog.ardes.com/2006/12/11/testing-singletons-with-ruby)
  class << Chef::Provider::Package::Yum::YumCache
    def reset_instance
      Singleton.send :__init__, self
      self
    end
  end

  before(:each) do
    yum_dump_good_output = <<EOF
[option installonlypkgs] kernel kernel-bigmem kernel-enterprise
erlang-mochiweb 0 1.4.1 5.el5 x86_64 ['erlang-mochiweb = 1.4.1-5.el5', 'mochiweb = 1.4.1-5.el5'] i installed
zip 0 2.31 2.el5 x86_64 ['zip = 2.31-2.el5'] r base
zisofs-tools 0 1.0.6 3.2.2 x86_64 [] a extras
zlib 0 1.2.3 3 x86_64 ['zlib = 1.2.3-3', 'libz.so.1()(64bit)'] r base
zlib 0 1.2.3 3 i386 ['zlib = 1.2.3-3', 'libz.so.1'] r base
zlib-devel 0 1.2.3 3 i386 [] a extras
zlib-devel 0 1.2.3 3 x86_64 ['zlib-devel = 1.2.3-3'] r base
znc 0 0.098 1.el5 x86_64 [] a base
znc-devel 0 0.098 1.el5 i386 [] a extras
znc-devel 0 0.098 1.el5 x86_64 [] a base
znc-extra 0 0.098 1.el5 x86_64 [] a base
znc-modtcl 0 0.098 1.el5 x86_64 [] a base
znc-test.beta1 0 0.098 1.el5 x86_64 [] a extras
znc-test.test.beta1 0 0.098 1.el5 x86_64 [] a base
EOF

    yum_dump_bad_output_separators = <<EOF
zip 0 2.31 2.el5 x86_64 ['zip = 2.31-2.el5'] r base
zlib 0 1.2.3 3 x86_64 ['zlib = 1.2.3-3', 'libz.so.1()(64bit)'] i base bad
zlib-devel 0 1.2.3 3 i386 [] a extras
bad zlib-devel 0 1.2.3 3 x86_64 ['zlib-devel = 1.2.3-3'] i installed
znc-modtcl 0 0.098 1.el5 x86_64 [] a base bad
EOF

    yum_dump_bad_output_type = <<EOF
zip 0 2.31 2.el5 x86_64 ['zip = 2.31-2.el5'] r base
zlib 0 1.2.3 3 x86_64 ['zlib = 1.2.3-3', 'libz.so.1()(64bit)'] c base
zlib-devel 0 1.2.3 3 i386 [] a extras
zlib-devel 0 1.2.3 3 x86_64 ['zlib-devel = 1.2.3-3'] bad installed
znc-modtcl 0 0.098 1.el5 x86_64 [] a base
EOF

    yum_dump_error = <<EOF
yum-dump Config Error: File contains no section headers.
file: file://///etc/yum.repos.d/CentOS-Base.repo, line: 12
'qeqwewe\n'
EOF

    @status = mock("Status", :exitstatus => 0)
    @status_bad = mock("Status", :exitstatus => 1)
    @stdin = mock("STDIN", :nil_object => true)
    @stdout = mock("STDOUT", :nil_object => true)
    @stdout_good = yum_dump_good_output.split("\n")
    @stdout_bad_type = yum_dump_bad_output_type.split("\n")
    @stdout_bad_separators = yum_dump_bad_output_separators.split("\n")
    @stderr = mock("STDERR", :nil_object => true)
    @stderr.stub!(:readlines).and_return(yum_dump_error.split("\n"))
    @pid = mock("PID", :nil_object => true)

    # new singleton each time
    Chef::Provider::Package::Yum::YumCache.reset_instance
    @yc = Chef::Provider::Package::Yum::YumCache.instance
    # load valid data
    @yc.stub!(:popen4).and_yield(@pid, @stdin, @stdout_good, @stderr).and_return(@status)
  end

  describe "#new" do
    it "should return a Chef::Provider::Package::Yum::YumCache object" do
      @yc.should be_kind_of(Chef::Provider::Package::Yum::YumCache)
    end

    it "should register reload for start of Chef::Client runs" do
      Chef::Provider::Package::Yum::YumCache.reset_instance
      Chef::Client.should_receive(:when_run_starts) do |&b|
        b.should_not be_nil
      end
      @yc = Chef::Provider::Package::Yum::YumCache.instance
    end
  end

  describe "#refresh" do
    it "should implicitly call yum-dump.py only once by default after being instantiated" do
      @yc.should_receive(:popen4).once
      @yc.installed_version("zlib")
      @yc.reset
      @yc.installed_version("zlib")
    end

    it "should run yum-dump.py using the system python when next_refresh is for :all" do
      @yc.reload
      @yc.should_receive(:popen4).with(%r{^/usr/bin/python .*/yum-dump.py --options --installed-provides$}, :waitlast=>true)
      @yc.refresh
    end

    it "should run yum-dump.py with the installed flag when next_refresh is for :installed" do
      @yc.reload_installed
      @yc.should_receive(:popen4).with(%r{^/usr/bin/python .*/yum-dump.py --installed$}, :waitlast=>true)
      @yc.refresh
    end

    it "should run yum-dump.py with the all-provides flag when next_refresh is for :provides" do
      @yc.reload_provides
      @yc.should_receive(:popen4).with(%r{^/usr/bin/python .*/yum-dump.py --options --all-provides$}, :waitlast=>true)
      @yc.refresh
    end

    it "should warn about invalid data with too many separators" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, @stdout_bad_separators, @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(3).times.with(%r{Problem parsing})
      @yc.refresh
    end

    it "should warn about invalid data with an incorrect type" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, @stdout_bad_type, @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(2).times.with(%r{Problem parsing})
      @yc.refresh
    end

    it "should warn about no output from yum-dump.py" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, [], @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(1).times.with(%r{no output from yum-dump.py})
      @yc.refresh
    end

    it "should raise exception yum-dump.py exits with a non zero status" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, [], @stderr).and_return(@status_bad)
      lambda { @yc.refresh}.should raise_error(Chef::Exceptions::Package, %r{CentOS-Base.repo, line: 12})
    end

    it "should parse type 'i' into an installed state for a package" do
      @yc.available_version("erlang-mochiweb").should be == nil
      @yc.installed_version("erlang-mochiweb").should_not be == nil
    end

    it "should parse type 'a' into an available state for a package" do
      @yc.available_version("znc").should_not be == nil
      @yc.installed_version("znc").should be == nil
    end

    it "should parse type 'r' into an installed and available states for a package" do
      @yc.available_version("zip").should_not be == nil
      @yc.installed_version("zip").should_not be == nil
    end

    it "should parse installonlypkgs from yum-dump.py options output" do
      @yc.allow_multi_install.should be == %w{kernel kernel-bigmem kernel-enterprise}
    end
  end

  describe "#installed_version" do
    it "should take one or two arguments" do
      lambda { @yc.installed_version("zip") }.should_not raise_error(ArgumentError)
      lambda { @yc.installed_version("zip", "i386") }.should_not raise_error(ArgumentError)
      lambda { @yc.installed_version("zip", "i386", "extra") }.should raise_error(ArgumentError)
    end

    it "should return version-release for matching package regardless of arch" do
      @yc.installed_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.installed_version("zip", nil).should be == "2.31-2.el5"
    end

    it "should return version-release for matching package and arch" do
      @yc.installed_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.installed_version("zisofs-tools", "i386").should be == nil
    end

    it "should return nil for an unmatched package" do
      @yc.installed_version(nil, nil).should be == nil
      @yc.installed_version("test1", nil).should be == nil
      @yc.installed_version("test2", "x86_64").should be == nil
    end
  end

  describe "#available_version" do
    it "should take one or two arguments" do
      lambda { @yc.available_version("zisofs-tools") }.should_not raise_error(ArgumentError)
      lambda { @yc.available_version("zisofs-tools", "i386") }.should_not raise_error(ArgumentError)
      lambda { @yc.available_version("zisofs-tools", "i386", "extra") }.should raise_error(ArgumentError)
    end

    it "should return version-release for matching package regardless of arch" do
      @yc.available_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.available_version("zip", nil).should be == "2.31-2.el5"
    end

    it "should return version-release for matching package and arch" do
      @yc.available_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.available_version("zisofs-tools", "i386").should be == nil
    end

    it "should return nil for an unmatched package" do
      @yc.available_version(nil, nil).should be == nil
      @yc.available_version("test1", nil).should be == nil
      @yc.available_version("test2", "x86_64").should be == nil
    end
  end

  describe "#version_available?" do
    it "should take two or three arguments" do
      lambda { @yc.version_available?("zisofs-tools") }.should raise_error(ArgumentError)
      lambda { @yc.version_available?("zisofs-tools", "1.0.6-3.2.2") }.should_not raise_error(ArgumentError)
      lambda { @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "x86_64") }.should_not raise_error(ArgumentError)
    end

    it "should return true if our package-version-arch is available" do
      @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "x86_64").should be == true
    end

    it "should return true if our package-version, no arch, is available" do
      @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", nil).should be == true
      @yc.version_available?("zisofs-tools", "1.0.6-3.2.2").should be == true
    end

    it "should return false if our package-version-arch isn't available" do
      @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "pretend").should be == false
      @yc.version_available?("zisofs-tools", "pretend", "x86_64").should be == false
      @yc.version_available?("pretend", "1.0.6-3.2.2", "x86_64").should be == false
    end

    it "should return false if our package-version, no arch, isn't available" do
      @yc.version_available?("zisofs-tools", "pretend", nil).should be == false
      @yc.version_available?("zisofs-tools", "pretend").should be == false
      @yc.version_available?("pretend", "1.0.6-3.2.2").should be == false
    end
  end

  describe "#package_repository" do
    it "should take two or three arguments" do
      lambda { @yc.package_repository("zisofs-tools") }.should raise_error(ArgumentError)
      lambda { @yc.package_repository("zisofs-tools", "1.0.6-3.2.2") }.should_not raise_error(ArgumentError)
      lambda { @yc.package_repository("zisofs-tools", "1.0.6-3.2.2", "x86_64") }.should_not raise_error(ArgumentError)
    end

    it "should return repoid for package-version-arch" do
      @yc.package_repository("zlib-devel", "1.2.3-3", "i386").should be == "extras"
      @yc.package_repository("zlib-devel", "1.2.3-3", "x86_64").should be == "base"
    end

    it "should return repoid for package-version, no arch" do
      @yc.package_repository("zisofs-tools", "1.0.6-3.2.2", nil).should be == "extras"
      @yc.package_repository("zisofs-tools", "1.0.6-3.2.2").should be == "extras"
    end

    it "should return nil when no match for package-version-arch" do
      @yc.package_repository("zisofs-tools", "1.0.6-3.2.2", "pretend").should be == nil
      @yc.package_repository("zisofs-tools", "pretend", "x86_64").should be == nil
      @yc.package_repository("pretend", "1.0.6-3.2.2", "x86_64").should be == nil
    end

    it "should return nil when no match for package-version, no arch" do
      @yc.package_repository("zisofs-tools", "pretend", nil).should be == nil 
      @yc.package_repository("zisofs-tools", "pretend").should be == nil
      @yc.package_repository("pretend", "1.0.6-3.2.2").should be == nil
    end
  end

  describe "#reset" do
    it "should empty the installed and available packages RPMDb" do
      @yc.available_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.installed_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.reset
      @yc.available_version("zip", "x86_64").should be == nil
      @yc.installed_version("zip", "x86_64").should be == nil
    end
  end

  describe "#package_available?" do
    it "should return true a package name is available" do
      @yc.package_available?("zisofs-tools").should be == true
      @yc.package_available?("moo").should be == false
      @yc.package_available?(nil).should be == false
    end

    it "should return true a package name + arch is available" do
      @yc.package_available?("zlib-devel.i386").should be == true
      @yc.package_available?("zisofs-tools.x86_64").should be == true
      @yc.package_available?("znc-test.beta1.x86_64").should be == true
      @yc.package_available?("znc-test.beta1").should be == true
      @yc.package_available?("znc-test.test.beta1").should be == true
      @yc.package_available?("moo.i386").should be == false
      @yc.package_available?("zisofs-tools.beta").should be == false
      @yc.package_available?("znc-test.test").should be == false
    end
  end
end
