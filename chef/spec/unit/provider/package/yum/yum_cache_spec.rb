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

  let(:yum_dump_good_output) { <<EOF }
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

  let(:yum_dump_bad_output_separators) { <<EOF }
zip 0 2.31 2.el5 x86_64 ['zip = 2.31-2.el5'] r base
zlib 0 1.2.3 3 x86_64 ['zlib = 1.2.3-3', 'libz.so.1()(64bit)'] i base bad
zlib-devel 0 1.2.3 3 i386 [] a extras
bad zlib-devel 0 1.2.3 3 x86_64 ['zlib-devel = 1.2.3-3'] i installed
znc-modtcl 0 0.098 1.el5 x86_64 [] a base bad
EOF

  let(:yum_dump_bad_output_type) { <<EOF }
zip 0 2.31 2.el5 x86_64 ['zip = 2.31-2.el5'] r base
zlib 0 1.2.3 3 x86_64 ['zlib = 1.2.3-3', 'libz.so.1()(64bit)'] c base
zlib-devel 0 1.2.3 3 i386 [] a extras
zlib-devel 0 1.2.3 3 x86_64 ['zlib-devel = 1.2.3-3'] bad installed
znc-modtcl 0 0.098 1.el5 x86_64 [] a base
EOF

  let(:yum_dump_error) { <<EOF }
yum-dump Config Error: File contains no section headers.
file: file://///etc/yum.repos.d/CentOS-Base.repo, line: 12
'qeqwewe\n'
EOF

  let(:stdout) { StringIO.new }
  let(:stdout_good) { StringIO.new(yum_dump_good_output) }
  let(:stdout_bad_type) { StringIO.new(yum_dump_bad_output_type) }
  let(:stdout_bad_separators) { StringIO.new(yum_dump_bad_output_separators) }

  let(:stderr) { StringIO.new }
  let(:status) { mock("Status", :exitstatus => exitstatus, :stdout => stdout, :stderr => stderr) }
  let(:exitstatus) { 0 }

  # new singleton each time
  let(:singleton_instance) { Chef::Provider::Package::Yum::YumCache.tap(&:reset_instance).instance }
  let(:yc) { singleton_instance }

  # load valid data
  let(:assume_stderr_returns_dump_error) { stderr.stub!(:readlines).and_return(yum_dump_error.split("\n")) }
  let(:assume_yc_has_valid_data) { yc.stub!(:shell_out!).and_return(status) }

  describe "#new" do
    it "should return a Chef::Provider::Package::Yum::YumCache object" do
      yc.should be_kind_of(Chef::Provider::Package::Yum::YumCache)
    end

    it "should register reload for start of Chef::Client runs" do
      Chef::Provider::Package::Yum::YumCache.reset_instance
      Chef::Client.should_receive(:when_run_starts) do |&b|
        b.should_not be_nil
      end
      Chef::Provider::Package::Yum::YumCache.instance
    end
  end

  describe "#refresh" do
    it "should implicitly call yum-dump.py only once by default after being instantiated" do
      assume_yc_has_valid_data
      yc.should_receive(:shell_out!).once
      yc.installed_version("zlib")
      yc.reset
      yc.installed_version("zlib")
    end

    it "should run yum-dump.py using the system python when next_refresh is for :all" do
      assume_yc_has_valid_data
      yc.reload
      yc.should_receive(:shell_out!).with(%r{^/usr/bin/python .*/yum-dump.py --options --installed-provides$})
      yc.refresh
    end

    it "should run yum-dump.py with the installed flag when next_refresh is for :installed" do
      assume_yc_has_valid_data
      yc.reload_installed
      yc.should_receive(:shell_out!).with(%r{^/usr/bin/python .*/yum-dump.py --installed$})
      yc.refresh
    end

    it "should run yum-dump.py with the all-provides flag when next_refresh is for :provides" do
      yc.reload_provides
      yc.should_receive(:shell_out!).with(%r{^/usr/bin/python .*/yum-dump.py --options --all-provides$}).and_return(status)
      yc.refresh
    end

    context 'with invalid data with too many separators' do
      let(:stdout) { stdout_bad_separators }
      it "should emit warning" do
        yc.stub!(:shell_out!).and_return(status)
        Chef::Log.should_receive(:warn).exactly(3).times.with(%r{Problem parsing})
        yc.refresh
      end
    end

    context 'with invalid data with an incorrect type' do
      let(:stdout) { stdout_bad_type }
      it "should emit warning" do
        yc.stub!(:shell_out!).and_return(status)
        Chef::Log.should_receive(:warn).exactly(2).times.with(%r{Problem parsing})
        yc.refresh
      end
    end

    context 'with empty data' do
      let(:stdout) { StringIO.new }
      it "should emit warning" do
        yc.stub!(:shell_out!).and_return(status)
        Chef::Log.should_receive(:warn).exactly(1).times.with(%r{no output from yum-dump.py})
        yc.refresh
      end
    end

    context 'with non-zero status' do
      let(:exitstatus) { 1 }

      it "should raise exception yum-dump.py exits with a non zero status" do
        assume_yc_has_valid_data
        lambda { yc.refresh }.should raise_error(Chef::Exceptions::Package)
      end
    end

    context 'with valid data' do
      let(:stdout) { stdout_good }

      it "should parse type 'i' into an installed state for a package" do
        assume_yc_has_valid_data
        yc.available_version("erlang-mochiweb").should be_nil
        yc.installed_version("erlang-mochiweb").should_not be_nil
      end

      it "should parse type 'a' into an available state for a package" do
        assume_yc_has_valid_data
        yc.available_version("znc").should_not be_nil
        yc.installed_version("znc").should be_nil
      end

      it "should parse type 'r' into an installed and available states for a package" do
        assume_yc_has_valid_data
        yc.available_version("zip").should_not be_nil
        yc.installed_version("zip").should_not be_nil
      end

      it "should parse installonlypkgs from yum-dump.py options output" do
        assume_yc_has_valid_data
        yc.allow_multi_install.should eql(%w{kernel kernel-bigmem kernel-enterprise})
      end
    end
  end

  describe "#installed_version" do
    let(:stdout) { stdout_good }

    it "should take one or two arguments" do
      lambda { yc.installed_version("zip") }.should_not raise_error(ArgumentError)
      lambda { yc.installed_version("zip", "i386") }.should_not raise_error(ArgumentError)
      lambda { yc.installed_version("zip", "i386", "extra") }.should raise_error(ArgumentError)
    end

    it "should return version-release for matching package regardless of arch" do
      assume_yc_has_valid_data
      yc.installed_version("zip", "x86_64").should eql "2.31-2.el5"
      yc.installed_version("zip", nil).should eql "2.31-2.el5"
    end

    it "should return version-release for matching package and arch" do
      assume_yc_has_valid_data
      yc.installed_version("zip", "x86_64").should eql "2.31-2.el5"
      yc.installed_version("zisofs-tools", "i386").should be_nil
    end

    it "should return nil for an unmatched package" do
      assume_yc_has_valid_data
      yc.installed_version(nil, nil).should be_nil
      yc.installed_version("test1", nil).should be_nil
      yc.installed_version("test2", "x86_64").should be_nil
    end
  end

  describe "#available_version" do
    let(:stdout) { stdout_good }

    it "should take one or two arguments" do
      lambda { yc.available_version("zisofs-tools") }.should_not raise_error(ArgumentError)
      lambda { yc.available_version("zisofs-tools", "i386") }.should_not raise_error(ArgumentError)
      lambda { yc.available_version("zisofs-tools", "i386", "extra") }.should raise_error(ArgumentError)
    end

    it "should return version-release for matching package regardless of arch" do
      assume_yc_has_valid_data
      yc.available_version("zip", "x86_64").should eql "2.31-2.el5"
      yc.available_version("zip", nil).should eql "2.31-2.el5"
    end

    it "should return version-release for matching package and arch" do
      assume_yc_has_valid_data
      yc.available_version("zip", "x86_64").should eql "2.31-2.el5"
      yc.available_version("zisofs-tools", "i386").should be_nil
    end

    it "should return nil for an unmatched package" do
      assume_yc_has_valid_data
      yc.available_version(nil, nil).should be_nil
      yc.available_version("test1", nil).should be_nil
      yc.available_version("test2", "x86_64").should be_nil
    end
  end

  describe "#version_available?" do
    let(:stdout) { stdout_good }

    it "should take two or three arguments" do
      lambda { yc.version_available?("zisofs-tools") }.should raise_error(ArgumentError)
      lambda { yc.version_available?("zisofs-tools", "1.0.6-3.2.2") }.should_not raise_error(ArgumentError)
      lambda { yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "x86_64") }.should_not raise_error(ArgumentError)
    end

    it "should return true if our package-version-arch is available" do
      assume_yc_has_valid_data
      yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "x86_64").should be_true
    end

    it "should return true if our package-version, no arch, is available" do
      assume_yc_has_valid_data
      yc.version_available?("zisofs-tools", "1.0.6-3.2.2", nil).should be_true
      yc.version_available?("zisofs-tools", "1.0.6-3.2.2").should be_true
    end

    it "should return false if our package-version-arch isn't available" do
      assume_yc_has_valid_data
      yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "pretend").should be_false
      yc.version_available?("zisofs-tools", "pretend", "x86_64").should be_false
      yc.version_available?("pretend", "1.0.6-3.2.2", "x86_64").should be_false
    end

    it "should return false if our package-version, no arch, isn't available" do
      assume_yc_has_valid_data
      yc.version_available?("zisofs-tools", "pretend", nil).should be_false
      yc.version_available?("zisofs-tools", "pretend").should be_false
      yc.version_available?("pretend", "1.0.6-3.2.2").should be_false
    end
  end

  describe "#package_repository" do
    let(:stdout) { stdout_good }

    it "should take two or three arguments" do
      lambda { yc.package_repository("zisofs-tools") }.should raise_error(ArgumentError)
      lambda { yc.package_repository("zisofs-tools", "1.0.6-3.2.2") }.should_not raise_error(ArgumentError)
      lambda { yc.package_repository("zisofs-tools", "1.0.6-3.2.2", "x86_64") }.should_not raise_error(ArgumentError)
    end

    it "should return repoid for package-version-arch" do
      assume_yc_has_valid_data
      yc.package_repository("zlib-devel", "1.2.3-3", "i386").should eql "extras"
      yc.package_repository("zlib-devel", "1.2.3-3", "x86_64").should eql "base"
    end

    it "should return repoid for package-version, no arch" do
      assume_yc_has_valid_data
      yc.package_repository("zisofs-tools", "1.0.6-3.2.2", nil).should eql "extras"
      yc.package_repository("zisofs-tools", "1.0.6-3.2.2").should eql "extras"
    end

    it "should return nil when no match for package-version-arch" do
      assume_yc_has_valid_data
      yc.package_repository("zisofs-tools", "1.0.6-3.2.2", "pretend").should be_nil
      yc.package_repository("zisofs-tools", "pretend", "x86_64").should be_nil
      yc.package_repository("pretend", "1.0.6-3.2.2", "x86_64").should be_nil
    end

    it "should return nil when no match for package-version, no arch" do
      assume_yc_has_valid_data
      yc.package_repository("zisofs-tools", "pretend", nil).should be_nil
      yc.package_repository("zisofs-tools", "pretend").should be_nil
      yc.package_repository("pretend", "1.0.6-3.2.2").should be_nil
    end
  end

  describe "#reset" do
    let(:stdout) { stdout_good }

    it "should empty the installed and available packages RPMDb" do
      assume_yc_has_valid_data
      yc.available_version("zip", "x86_64").should eql "2.31-2.el5"
      yc.installed_version("zip", "x86_64").should eql "2.31-2.el5"
      yc.reset
      yc.available_version("zip", "x86_64").should be_nil
      yc.installed_version("zip", "x86_64").should be_nil
    end
  end

  describe "#package_available?" do
    let(:stdout) { stdout_good }

    it "should return true a package name is available" do
      assume_yc_has_valid_data
      yc.package_available?("zisofs-tools").should be_true
      yc.package_available?("moo").should be_false
      yc.package_available?(nil).should be_false
    end

    it "should return true a package name + arch is available" do
      assume_yc_has_valid_data
      yc.package_available?("zlib-devel.i386").should be_true
      yc.package_available?("zisofs-tools.x86_64").should be_true
      yc.package_available?("znc-test.beta1.x86_64").should be_true
      yc.package_available?("znc-test.beta1").should be_true
      yc.package_available?("znc-test.test.beta1").should be_true
      yc.package_available?("moo.i386").should be_false
      yc.package_available?("zisofs-tools.beta").should be_false
      yc.package_available?("znc-test.test").should be_false
    end
  end
end
