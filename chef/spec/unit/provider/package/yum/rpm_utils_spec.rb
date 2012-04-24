require 'spec_helper'

describe Chef::Provider::Package::Yum::RPMUtils do
  describe "#version_parse" do
    before do
      @rpmutils = Chef::Provider::Package::Yum::RPMUtils
    end

    it "parses known good epoch strings" do
      [
        [ "0:3.3", [ 0, "3.3", nil ] ],
        [ "9:1.7.3", [ 9, "1.7.3", nil ] ],
        [ "15:20020927", [ 15, "20020927", nil ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses strange epoch strings" do
      [
        [ ":3.3", [ 0, "3.3", nil ] ],
        [ "-1:1.7.3", [ nil, nil, "1:1.7.3" ] ],
        [ "-:20020927", [ nil, nil, ":20020927" ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses known good version strings" do
      [
        [ "3.3", [ nil, "3.3", nil ] ],
        [ "1.7.3", [ nil, "1.7.3", nil ] ],
        [ "20020927", [ nil, "20020927", nil ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses strange version strings" do
      [
        [ "3..3", [ nil, "3..3", nil ] ],
        [ "0001.7.3", [ nil, "0001.7.3", nil ] ],
        [ "20020927,3", [ nil, "20020927,3", nil ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses known good version release strings" do
      [
        [ "3.3-0.pre3.1.60.el5_5.1", [ nil, "3.3", "0.pre3.1.60.el5_5.1" ] ],
        [ "1.7.3-1jpp.2.el5", [ nil, "1.7.3", "1jpp.2.el5" ] ],
        [ "20020927-46.el5", [ nil, "20020927", "46.el5" ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses strange version release strings" do
      [
        [ "3.3-", [ nil, "3.3", nil ] ],
        [ "-1jpp.2.el5", [ nil, nil, "1jpp.2.el5" ] ],
        [ "-0020020927-46.el5", [ nil, "-0020020927", "46.el5" ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end
  end

  describe "#rpmvercmp" do
    before do
      @rpmutils = Chef::Provider::Package::Yum::RPMUtils
    end

    it "should validate version compare logic for standard examples" do
      [
        # numeric
        [ "0.0.2", "0.0.1", 1 ],
        [ "0.2.0", "0.1.0", 1 ],
        [ "2.0.0", "1.0.0", 1 ],
        [ "0.0.1", "0.0.1", 0 ],
        [ "0.0.1", "0.0.2", -1 ],
        [ "0.1.0", "0.2.0", -1 ],
        [ "1.0.0", "2.0.0", -1 ],
        # alpha
        [ "bb", "aa", 1 ],
        [ "ab", "aa", 1 ],
        [ "aa", "aa", 0 ],
        [ "aa", "bb", -1 ],
        [ "aa", "ab", -1 ],
        [ "BB", "AA", 1 ],
        [ "AA", "AA", 0 ],
        [ "AA", "BB", -1 ],
        [ "aa", "AA", 1 ],
        [ "AA", "aa", -1 ],
        # alphanumeric
        [ "0.0.1b", "0.0.1a", 1 ],
        [ "0.1b.0", "0.1a.0", 1 ],
        [ "1b.0.0", "1a.0.0", 1 ],
        [ "0.0.1a", "0.0.1a", 0 ],
        [ "0.0.1a", "0.0.1b", -1 ],
        [ "0.1a.0", "0.1b.0", -1 ],
        [ "1a.0.0", "1b.0.0", -1 ],
        # alphanumeric against alphanumeric
        [ "0.0.1", "0.0.a", 1 ],
        [ "0.1.0", "0.a.0", 1 ],
        [ "1.0.0", "a.0.0", 1 ],
        [ "0.0.a", "0.0.a", 0 ],
        [ "0.0.a", "0.0.1", -1 ],
        [ "0.a.0", "0.1.0", -1 ],
        [ "a.0.0", "1.0.0", -1 ],
        # alphanumeric against numeric
        [ "0.0.2", "0.0.1a", 1 ],
        [ "0.0.2a", "0.0.1", 1 ],
        [ "0.0.1", "0.0.2a", -1 ],
        [ "0.0.1a", "0.0.2", -1 ],
        # length
        [ "0.0.1aa", "0.0.1a", 1 ],
        [ "0.0.1aa", "0.0.1aa", 0 ],
        [ "0.0.1a", "0.0.1aa", -1 ],
     ].each do |x, y, result|
        @rpmutils.rpmvercmp(x,y).should == result
      end
    end

    it "should validate version compare logic for strange examples" do
      [
        [ "2,0,0", "1.0.0", 1 ],
        [ "0.0.1", "0,0.1", 0 ],
        [ "1.0.0", "2,0,0", -1 ],
        [ "002.0.0", "001.0.0", 1 ],
        [ "001..0.1", "001..0.0", 1 ],
        [ "-001..1", "-001..0", 1 ],
        [ "1.0.1", nil, 1 ],
        [ nil, nil, 0 ],
        [ nil, "1.0.1", -1 ],
        [ "1.0.1", "", 1 ],
        [ "", "", 0 ],
        [ "", "1.0.1", -1 ]
     ].each do |x, y, result|
        @rpmutils.rpmvercmp(x,y).should == result
      end
    end

    it "tests isalnum good input" do
      [ 'a', 'z', 'A', 'Z', '0', '9' ].each do |t|
        @rpmutils.isalnum(t).should == true
      end
    end

    it "tests isalnum bad input" do
      [ '-', '.', '!', '^', ':', '_' ].each do |t|
        @rpmutils.isalnum(t).should == false
      end
    end

    it "tests isalpha good input" do
      [ 'a', 'z', 'A', 'Z', ].each do |t|
        @rpmutils.isalpha(t).should == true
      end
    end

    it "tests isalpha bad input" do
      [ '0', '9', '-', '.', '!', '^', ':', '_' ].each do |t|
        @rpmutils.isalpha(t).should == false
      end
    end

    it "tests isdigit good input" do
      [ '0', '9', ].each do |t|
        @rpmutils.isdigit(t).should == true
      end
    end

    it "tests isdigit bad input" do
      [ 'A', 'z', '-', '.', '!', '^', ':', '_' ].each do |t|
        @rpmutils.isdigit(t).should == false
      end
    end
  end

end
