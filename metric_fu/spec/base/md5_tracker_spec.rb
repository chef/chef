require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe MetricFu::MD5Tracker do
  before do
    @tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
    FileUtils.mkdir_p(@tmp_dir, :verbose => false) unless File.directory?(@tmp_dir)
    @file1 = File.new(File.join(@tmp_dir, 'file1.txt'), 'w')
    @file2 = File.new(File.join(@tmp_dir, 'file2.txt'), 'w')
  end

  after do
    FileUtils.rm_rf(@tmp_dir, :verbose => false)
  end

  it "identical files should match" do
    @file1.puts("Hello World")
    @file1.close
    file1_md5 = MD5Tracker.track(@file1.path, @tmp_dir)

    @file2.puts("Hello World")
    @file2.close
    file2_md5 = MD5Tracker.track(@file2.path, @tmp_dir)

    file2_md5.should == file1_md5
  end

  it "different files should not match" do
    @file1.puts("Hello World")
    @file1.close
    file1_md5 = MD5Tracker.track(@file1.path, @tmp_dir)

    @file2.puts("Goodbye World")
    @file2.close
    file2_md5 = MD5Tracker.track(@file2.path, @tmp_dir)

    file2_md5.should_not == file1_md5
  end

  it "file_changed? should detect a change" do
      @file2.close

      @file1.puts("Hello World")
      @file1.close
      file1_md5 = MD5Tracker.track(@file1.path, @tmp_dir)

      @file1 = File.new(File.join(@tmp_dir, 'file1.txt'), 'w')
      @file1.puts("Goodbye World")
      @file1.close
      MD5Tracker.file_changed?(@file1.path, @tmp_dir).should be_true
  end

  it "should detect a new file" do
    @file2.close
    MD5Tracker.file_changed?(@file1.path, @tmp_dir).should be_true
    File.exist?(MD5Tracker.md5_file(@file1.path, @tmp_dir)).should be_true
  end
end
