require File.join(File.dirname(__FILE__), "/../spec_helper")

describe FileEdit, "initialiize" do
  it "should create a new FileEdit object" do
    FileEdit.new("./spec/data/fileedit/hosts").should be_kind_of(FileEdit)
  end
  
  it "should throw an exception if the input file does not exist" do
    lambda{FileEdit.new("nonexistfile")}.should raise_error
  end

  it "should throw an exception if the input file is blank" do
    lambda{FileEdit.new("./spec/data/fileedit/blank")}.should raise_error 
  end
  
end

describe FileEdit, "search_file_replace" do
  
  it "should accept regex passed in as a string (not Regexp object) and replace the match if there is one" do
    helper_method("./spec/data/fileedit/hosts", "localhost", true)
  end
  

  it "should accept regex passed in as a Regexp object and replace the match if there is one" do
    helper_method("./spec/data/fileedit/hosts", /localhost/, true)
  end

  
  it "should do nothing if there isn't a match" do
    helper_method("./spec/data/fileedit/hosts", /pattern/, false)
  end

  
  def helper_method(filename, regex, value)
    fedit = FileEdit.new(filename)
    fedit.search_file_replace(regex, "replacement")
    fedit.write_file
    (File.exist? filename+".old").should be(value)
    if value == true
      newfile = File.new(filename).readlines 
      newfile[0].should match(/replacement/)
      File.delete("./spec/data/fileedit/hosts")
      File.rename("./spec/data/fileedit/hosts.old", "./spec/data/fileedit/hosts")
    end
  end
  
end

describe FileEdit, "search_file_replace_line" do

  it "should search for match and replace the whole line" do
    fedit = FileEdit.new("./spec/data/fileedit/hosts")
    fedit.search_file_replace_line(/localhost/, "replacement line")
    fedit.write_file
    newfile = File.new("./spec/data/fileedit/hosts").readlines
    newfile[0].should match(/replacement/)
    newfile[0].should_not match(/127/)
    File.delete("./spec/data/fileedit/hosts")
    File.rename("./spec/data/fileedit/hosts.old", "./spec/data/fileedit/hosts")
  end
  
end

describe FileEdit, "search_file_delete" do
  it "should search for match and delete the match" do
    fedit = FileEdit.new("./spec/data/fileedit/hosts")
    fedit.search_file_delete(/localhost/)
    fedit.write_file
    newfile = File.new("./spec/data/fileedit/hosts").readlines
    newfile[0].should_not match(/localhost/)
    newfile[0].should match(/127/)
    File.delete("./spec/data/fileedit/hosts")
    File.rename("./spec/data/fileedit/hosts.old", "./spec/data/fileedit/hosts")
  end
end

describe FileEdit, "search_file_delete_line" do
  it "should search for match and delete the matching line" do
    fedit = FileEdit.new("./spec/data/fileedit/hosts")
    fedit.search_file_delete_line(/localhost/)
    fedit.write_file
    newfile = File.new("./spec/data/fileedit/hosts").readlines
    newfile[0].should_not match(/localhost/)
    newfile[0].should match(/broadcasthost/)
    File.delete("./spec/data/fileedit/hosts")
    File.rename("./spec/data/fileedit/hosts.old", "./spec/data/fileedit/hosts")
  end
end

describe FileEdit, "insert_line_after_match" do
  it "should search for match and insert the given line after the matching line" do
    fedit = FileEdit.new("./spec/data/fileedit/hosts")
    fedit.insert_line_after_match(/localhost/, "new line inserted")
    fedit.write_file
    newfile = File.new("./spec/data/fileedit/hosts").readlines
    newfile[1].should match(/new/)
    File.delete("./spec/data/fileedit/hosts")
    File.rename("./spec/data/fileedit/hosts.old", "./spec/data/fileedit/hosts")
  end
  
end






