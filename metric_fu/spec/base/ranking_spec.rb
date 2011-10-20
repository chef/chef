require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Ranking do

  context "with many items" do

    specify "it should give top x items" do
      ranking = Ranking.new
      ranking[:a] = 10
      ranking[:b] = 50
      ranking[:c] = 1
      ranking.top(2).should == [:b,:a]
    end

    specify "if gives all items if param is not numeric" do
      ranking = Ranking.new
      ranking[:a] = 10
      ranking[:b] = 50
      ranking[:c] = 1
      ranking.top(nil).should == [:b,:a, :c]
      ranking.top(:all).should == [:b,:a, :c]
    end

    specify "lowest item is at 0 percentile" do
      ranking = Ranking.new
      ranking[:a] = 10
      ranking[:b] = 50
      ranking.percentile(:a).should == 0
    end

    specify "highest item is at high percentile" do
      ranking = Ranking.new
      ranking[:a] = 10
      ranking[:b] = 50
      ranking[:c] = 0
      ranking[:d] = 5
      ranking.percentile(:b).should == 0.75
    end

  end

end
