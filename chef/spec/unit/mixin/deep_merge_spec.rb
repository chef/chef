#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Author:: Steve Midgley (http://www.misuse.org/science)
# Copyright:: Copyright (c) 2010 Matthew Kent
# Copyright:: Copyright (c) 2008 Steve Midgley
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Notice:
# This code is imported from deep_merge by Steve Midgley. deep_merge is
# available under the MIT license from
# http://trac.misuse.org/science/wiki/DeepMerge

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

# Test coverage from the original author converted to rspec
describe Chef::Mixin::DeepMerge, "deep_merge!" do
  before do
    @dm = Chef::Mixin::DeepMerge
    #FIELD_KNOCKOUT_PREFIX = Chef::Mixin::DeepMerge::DEFAULT_FIELD_KNOCKOUT_PREFIX
    @field_ko_prefix = Chef::Mixin::DeepMerge::DEFAULT_FIELD_KNOCKOUT_PREFIX
  end
  #@dm = Chef::Mixin::DeepMerge


  # deep_merge core tests - moving from basic to more complex

  it "tests merging an hash w/array into blank hash" do
    hash_src = {'id' => '2'}
    hash_dst = {}
    @dm.deep_merge!(hash_src.dup, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == hash_src
  end

  it "tests merging an hash w/array into blank hash" do
    hash_src = {'region' => {'id' => ['227', '2']}}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == hash_src
  end

  it "tests merge from empty hash" do
    hash_src = {}
    hash_dst = {"property" => ["2","4"]}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => ["2","4"]}
  end

  it "tests merge to empty hash" do
    hash_src = {"property" => ["2","4"]}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => ["2","4"]}
  end

  it "tests simple string overwrite" do
    hash_src = {"name" => "value"}
    hash_dst = {"name" => "value1"}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"name" => "value"}
  end

  it "tests simple string overwrite of empty hash" do
    hash_src = {"name" => "value"}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == hash_src
  end

  it "tests hashes holding array" do
    hash_src = {"property" => ["1","3"]}
    hash_dst = {"property" => ["2","4"]}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => ["2","4","1","3"]}
  end

  it "tests hashes holding array (sorted)" do
    hash_src = {"property" => ["1","3"]}
    hash_dst = {"property" => ["2","4"]}
    @dm.deep_merge!(hash_src, hash_dst, {:sort_merged_arrays => true})
    hash_dst.should == {"property" => ["1","2","3","4"]}
  end

  it "tests hashes holding hashes holding arrays (array with duplicate elements is merged with dest then src" do
    hash_src = {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => ["3", "2"], "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => ["3","2","1"], "bathroom_count" => ["2", "1", "4+"]}}
  end

  it "tests hash holding hash holding array v string (string is overwritten by array)" do
    hash_src = {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => "3", "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["2","1","4+"]}}
  end

  it "tests hash holding hash holding array v string (string is NOT overwritten by array)" do
    hash_src = {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => "3", "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:preserve_unmergeables => true})
    hash_dst.should == {"property" => {"bedroom_count" => "3", "bathroom_count" => ["2","1","4+"]}}
  end

  it "tests hash holding hash holding string v array (array is overwritten by string)" do
    hash_src = {"property" => {"bedroom_count" => "3", "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => "3", "bathroom_count" => ["2","1","4+"]}}
  end

  it "tests hash holding hash holding string v array (array does NOT overwrite string)" do
    hash_src = {"property" => {"bedroom_count" => "3", "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:preserve_unmergeables => true})
    hash_dst.should == {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["2","1","4+"]}}
  end

  it "tests hash holding hash holding hash v array (array is overwritten by hash)" do
    hash_src = {"property" => {"bedroom_count" => {"king_bed" => 3, "queen_bed" => 1}, "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => 3, "queen_bed" => 1}, "bathroom_count" => ["2","1","4+"]}}
  end

  it "tests hash holding hash holding hash v array (array is NOT overwritten by hash)" do
    hash_src = {"property" => {"bedroom_count" => {"king_bed" => 3, "queen_bed" => 1}, "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:preserve_unmergeables => true})
    hash_dst.should == {"property" => {"bedroom_count" => ["1", "2"], "bathroom_count" => ["2","1","4+"]}}
  end

  it "tests 3 hash layers holding integers (integers are overwritten by source)" do
    hash_src = {"property" => {"bedroom_count" => {"king_bed" => 3, "queen_bed" => 1}, "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => 2, "queen_bed" => 4}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => 3, "queen_bed" => 1}, "bathroom_count" => ["2","1","4+"]}}
  end

  it "tests 3 hash layers holding arrays of int (arrays are merged)" do
    hash_src = {"property" => {"bedroom_count" => {"king_bed" => [3], "queen_bed" => [1]}, "bathroom_count" => ["1", "4+"]}}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => [2,3], "queen_bed" => [4,1]}, "bathroom_count" => ["2","1","4+"]}}
  end

  it "tests 1 hash overwriting 3 hash layers holding arrays of int" do
    hash_src = {"property" => "1"}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => "1"}
  end

  it "tests 1 hash NOT overwriting 3 hash layers holding arrays of int" do
    hash_src = {"property" => "1"}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:preserve_unmergeables => true})
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
  end

  it "tests 3 hash layers holding arrays of int (arrays are merged) but second hash's array is overwritten" do
    hash_src = {"property" => {"bedroom_count" => {"king_bed" => [3], "queen_bed" => [1]}, "bathroom_count" => "1"}}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => [2,3], "queen_bed" => [4,1]}, "bathroom_count" => "1"}}
  end

  it "tests 3 hash layers holding arrays of int (arrays are merged) but second hash's array is NOT overwritten" do
    hash_src = {"property" => {"bedroom_count" => {"king_bed" => [3], "queen_bed" => [1]}, "bathroom_count" => "1"}}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:preserve_unmergeables => true})
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => [2,3], "queen_bed" => [4,1]}, "bathroom_count" => ["2"]}}
  end

  it "tests 3 hash layers holding arrays of int, but one holds int. This one overwrites, but the rest merge" do
    hash_src = {"property" => {"bedroom_count" => {"king_bed" => 3, "queen_bed" => [1]}, "bathroom_count" => ["1"]}}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => 3, "queen_bed" => [4,1]}, "bathroom_count" => ["2","1"]}}
  end

  it "tests 3 hash layers holding arrays of int, but source is incomplete." do
    hash_src = {"property" => {"bedroom_count" => {"king_bed" => [3]}, "bathroom_count" => ["1"]}}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => [2,3], "queen_bed" => [4]}, "bathroom_count" => ["2","1"]}}
  end

  it "tests 3 hash layers holding arrays of int, but source is shorter and has new 2nd level ints." do
    hash_src = {"property" => {"bedroom_count" => {2=>3, "king_bed" => [3]}, "bathroom_count" => ["1"]}}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {2=>3, "king_bed" => [2,3], "queen_bed" => [4]}, "bathroom_count" => ["2","1"]}}
  end

  it "tests 3 hash layers holding arrays of int, but source is empty" do
    hash_src = {}
    hash_dst = {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {"king_bed" => [2], "queen_bed" => [4]}, "bathroom_count" => ["2"]}}
  end

  it "tests 3 hash layers holding arrays of int, but dest is empty" do
    hash_src = {"property" => {"bedroom_count" => {2=>3, "king_bed" => [3]}, "bathroom_count" => ["1"]}}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"property" => {"bedroom_count" => {2=>3, "king_bed" => [3]}, "bathroom_count" => ["1"]}}
  end

  it "tests parameter management for knockout_prefix and overwrite unmergable" do
    hash_src = {"x" => 1}
    hash_dst = {"y" => 2}

    lambda {
      @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => ""})
    }.should raise_error(Chef::Mixin::DeepMerge::InvalidParameter)

    lambda {
      @dm.deep_merge!(hash_src, hash_dst, {:preserve_unmergeables => true, :knockout_prefix => ""})
    }.should raise_error(Chef::Mixin::DeepMerge::InvalidParameter)

    lambda {
      @dm.deep_merge!(hash_src, hash_dst, {:preserve_unmergeables => true, :knockout_prefix => "--"})
    }.should raise_error(Chef::Mixin::DeepMerge::InvalidParameter)

    lambda {
      @dm.deep_merge!(@dm.deep_merge!(hash_src, hash_dst))
    }.should_not raise_error(Chef::Mixin::DeepMerge::InvalidParameter)

    lambda {
      @dm.deep_merge!(hash_src, hash_dst, {:preserve_unmergeables => true})
    }.should_not raise_error(Chef::Mixin::DeepMerge::InvalidParameter)
  end

  it "tests hash holding arrays of arrays" do
    hash_src = {["1", "2", "3"] => ["1", "2"]}
    hash_dst = {["4", "5"] => ["3"]}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {["1","2","3"] => ["1", "2"], ["4", "5"] => ["3"]}
  end

  it "tests merging of hash with blank hash, and make sure that source array split still functions" do
    hash_src = {'property' => {'bedroom_count' => ["1","2,3"]}}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {'property' => {'bedroom_count' => ["1","2","3"]}}
  end

  it "tests merging of hash with blank hash, and make sure that source array split does not function when turned off" do
    hash_src = {'property' => {'bedroom_count' => ["1","2,3"]}}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {'property' => {'bedroom_count' => ["1","2,3"]}}
  end

  it "tests merging into a blank hash with overwrite_unmergeables turned on" do
    hash_src = {"action"=>"browse", "controller"=>"results"}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == hash_src
  end

  # KNOCKOUT_PREFIX testing
  # the next few tests are looking for correct behavior from specific real-world params/session merges
  # using the custom modifiers built for param/session merges

  [nil, ","].each do |ko_split|
    it "tests typical params/session style hash with knockout_merge elements" do
      hash_src = {"property"=>{"bedroom_count"=>[@field_ko_prefix+"1", "2", "3"]}}
      hash_dst = {"property"=>{"bedroom_count"=>["1", "2", "3"]}}
      @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ko_split})
      hash_dst.should == {"property"=>{"bedroom_count"=>["2", "3"]}}
    end

    it "tests typical params/session style hash with knockout_merge elements" do
      hash_src = {"property"=>{"bedroom_count"=>[@field_ko_prefix+"1", "2", "3"]}}
      hash_dst = {"property"=>{"bedroom_count"=>["3"]}}
      @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ko_split})
      hash_dst.should == {"property"=>{"bedroom_count"=>["3","2"]}}
    end

    it "tests typical params/session style hash with knockout_merge elements" do
      hash_src = {"property"=>{"bedroom_count"=>[@field_ko_prefix+"1", "2", "3"]}}
      hash_dst = {"property"=>{"bedroom_count"=>["4"]}}
      @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ko_split})
      hash_dst.should == {"property"=>{"bedroom_count"=>["4","2","3"]}}
    end

    it "tests typical params/session style hash with knockout_merge elements" do
      hash_src = {"property"=>{"bedroom_count"=>[@field_ko_prefix+"1", "2", "3"]}}
      hash_dst = {"property"=>{"bedroom_count"=>[@field_ko_prefix+"1", "4"]}}
      @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ko_split})
      hash_dst.should == {"property"=>{"bedroom_count"=>["4","2","3"]}}
    end

    it "tests typical params/session style hash with knockout_merge elements" do
      hash_src = {"amenity"=>{"id"=>[@field_ko_prefix+"1", @field_ko_prefix+"2", "3", "4"]}}
      hash_dst = {"amenity"=>{"id"=>["1", "2"]}}
      @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ko_split})
      hash_dst.should == {"amenity"=>{"id"=>["3","4"]}}
    end
  end

  it "tests special params/session style hash with knockout_merge elements in form src: [\"1\",\"2\"] dest:[\"--1,--2\", \"3,4\"]" do
    hash_src = {"amenity"=>{"id"=>[@field_ko_prefix+"1,"+@field_ko_prefix+"2", "3,4"]}}
    hash_dst = {"amenity"=>{"id"=>["1", "2"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"amenity"=>{"id"=>["3","4"]}}
  end

  it "tests same as previous but without ko_split value, this merge should fail" do
    hash_src = {"amenity"=>{"id"=>[@field_ko_prefix+"1,"+@field_ko_prefix+"2", "3,4"]}}
    hash_dst = {"amenity"=>{"id"=>["1", "2"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {"amenity"=>{"id"=>["1","2","3,4"]}}
  end

  it "tests special params/session style hash with knockout_merge elements in form src: [\"1\",\"2\"] dest:[\"--1,--2\", \"3,4\"]" do
    hash_src = {"amenity"=>{"id"=>[@field_ko_prefix+"1,2", "3,4", "--5", "6"]}}
    hash_dst = {"amenity"=>{"id"=>["1", "2"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"amenity"=>{"id"=>["2","3","4","6"]}}
  end

  it "tests special params/session style hash with knockout_merge elements in form src: [\"--1,--2\", \"3,4\", \"--5\", \"6\"] dest:[\"1,2\", \"3,4\"]" do
    hash_src = {"amenity"=>{"id"=>["#{@field_ko_prefix}1,#{@field_ko_prefix}2", "3,4", "#{@field_ko_prefix}5", "6"]}}
    hash_dst = {"amenity"=>{"id"=>["1", "2", "3", "4"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"amenity"=>{"id"=>["3","4","6"]}}
  end

  it "unamed upstream - tbd" do
    hash_src = {"url_regions"=>[], "region"=>{"ids"=>["227,233"]}, "action"=>"browse", "task"=>"browse", "controller"=>"results"}
    hash_dst = {"region"=>{"ids"=>["227"]}}
    @dm.deep_merge!(hash_src.dup, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"url_regions"=>[], "region"=>{"ids"=>["227","233"]}, "action"=>"browse", "task"=>"browse", "controller"=>"results"}
  end

  it "unamed upstream - tbd" do
    hash_src = {"region"=>{"ids"=>["--","227"], "id"=>"230"}}
    hash_dst = {"region"=>{"ids"=>["227", "233", "324", "230", "230"], "id"=>"230"}}
    @dm.deep_merge!(hash_src, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"region"=>{"ids"=>["227"], "id"=>"230"}}
  end

  it "unamed upstream - tbd" do
    hash_src = {"region"=>{"ids"=>["--","227", "232", "233"], "id"=>"232"}}
    hash_dst = {"region"=>{"ids"=>["227", "233", "324", "230", "230"], "id"=>"230"}}
    @dm.deep_merge!(hash_src, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"region"=>{"ids"=>["227", "232", "233"], "id"=>"232"}}
  end

  it "unamed upstream - tbd" do
    hash_src = {"region"=>{"ids"=>["--,227,232,233"], "id"=>"232"}}
    hash_dst = {"region"=>{"ids"=>["227", "233", "324", "230", "230"], "id"=>"230"}}
    @dm.deep_merge!(hash_src, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"region"=>{"ids"=>["227", "232", "233"], "id"=>"232"}}
  end

  it "unamed upstream - tbd" do
    hash_src = {"region"=>{"ids"=>["--,227,232","233"], "id"=>"232"}}
    hash_dst = {"region"=>{"ids"=>["227", "233", "324", "230", "230"], "id"=>"230"}}
    @dm.deep_merge!(hash_src, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"region"=>{"ids"=>["227", "232", "233"], "id"=>"232"}}
  end

  it "unamed upstream - tbd" do
    hash_src = {"region"=>{"ids"=>["--,227"], "id"=>"230"}}
    hash_dst = {"region"=>{"ids"=>["227", "233", "324", "230", "230"], "id"=>"230"}}
    @dm.deep_merge!(hash_src, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"region"=>{"ids"=>["227"], "id"=>"230"}}
  end

  it "unamed upstream - tbd" do
    hash_src = {"region"=>{"ids"=>["--,227"], "id"=>"230"}}
    hash_dst = {"region"=>{"ids"=>["227", "233", "324", "230", "230"], "id"=>"230"}, "action"=>"browse", "task"=>"browse", "controller"=>"results", "property_order_by"=>"property_type.descr"}
    @dm.deep_merge!(hash_src, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"region"=>{"ids"=>["227"], "id"=>"230"}, "action"=>"browse", "task"=>"browse",
      "controller"=>"results", "property_order_by"=>"property_type.descr"}
  end

  it "unamed upstream - tbd" do
    hash_src = {"query_uuid"=>"6386333d-389b-ab5c-8943-6f3a2aa914d7", "region"=>{"ids"=>["--,227"], "id"=>"230"}}
    hash_dst = {"query_uuid"=>"6386333d-389b-ab5c-8943-6f3a2aa914d7", "url_regions"=>[], "region"=>{"ids"=>["227", "233", "324", "230", "230"], "id"=>"230"}, "action"=>"browse", "task"=>"browse", "controller"=>"results", "property_order_by"=>"property_type.descr"}
    @dm.deep_merge!(hash_src, hash_dst, {:overwrite_unmergeables => true, :knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"query_uuid" => "6386333d-389b-ab5c-8943-6f3a2aa914d7", "url_regions"=>[],
      "region"=>{"ids"=>["227"], "id"=>"230"}, "action"=>"browse", "task"=>"browse",
      "controller"=>"results", "property_order_by"=>"property_type.descr"}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => "--"}
    hash_dst = {"amenity" => "1"}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => ""}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => ["--"]}
    hash_dst = {"amenity" => "1"}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => []}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => "--"}
    hash_dst = {"amenity" => ["1"]}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => ""}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => ["--"]}
    hash_dst = {"amenity" => ["1"]}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => []}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => ["--"]}
    hash_dst = {"amenity" => "1"}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => []}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => ["--", "2"]}
    hash_dst = {'amenity' => ["1", "3", "7+"]}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => ["2"]}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => ["--", "2"]}
    hash_dst = {'amenity' => "5"}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => ['2']}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => "--"}
    hash_dst = {"amenity"=>{"id"=>["1", "2", "3", "4"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => ""}
  end

  it "tests knock out entire dest hash if \"--\" is passed for source" do
    hash_src = {'amenity' => ["--"]}
    hash_dst = {"amenity"=>{"id"=>["1", "2", "3", "4"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => "--", :unpack_arrays => ","})
    hash_dst.should == {'amenity' => []}
  end

  it "tests knock out dest array if \"--\" is passed for source" do
    hash_src = {"region" => {'ids' => @field_ko_prefix}}
    hash_dst = {"region"=>{"ids"=>["1", "2", "3", "4"]}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {'region' => {'ids' => ""}}
  end

  it "tests knock out dest array but leave other elements of hash intact" do
    hash_src = {"region" => {'ids' => @field_ko_prefix}}
    hash_dst = {"region"=>{"ids"=>["1", "2", "3", "4"], 'id'=>'11'}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {'region' => {'ids' => "", 'id'=>'11'}}
  end

  it "tests knock out entire tree of dest hash" do
    hash_src = {"region" => @field_ko_prefix}
    hash_dst = {"region"=>{"ids"=>["1", "2", "3", "4"], 'id'=>'11'}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {'region' => ""}
  end

  it "tests knock out entire tree of dest hash - retaining array format" do
    hash_src = {"region" => {'ids' => [@field_ko_prefix]}}
    hash_dst = {"region"=>{"ids"=>["1", "2", "3", "4"], 'id'=>'11'}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {'region' => {'ids' => [], 'id'=>'11'}}
  end

  it "tests knock out entire tree of dest hash & replace with new content" do
    hash_src = {"region" => {'ids' => ["2", @field_ko_prefix, "6"]}}
    hash_dst = {"region"=>{"ids"=>["1", "2", "3", "4"], 'id'=>'11'}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {'region' => {'ids' => ["2", "6"], 'id'=>'11'}}
  end

  it "tests knock out entire tree of dest hash & replace with new content" do
    hash_src = {"region" => {'ids' => ["7", @field_ko_prefix, "6"]}}
    hash_dst = {"region"=>{"ids"=>["1", "2", "3", "4"], 'id'=>'11'}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {'region' => {'ids' => ["7", "6"], 'id'=>'11'}}
  end

  it "tests edge test: make sure that when we turn off knockout_prefix that all values are processed correctly" do
    hash_src = {"region" => {'ids' => ["7", "--", "2", "6,8"]}}
    hash_dst = {"region"=>{"ids"=>["1", "2", "3", "4"], 'id'=>'11'}}
    @dm.deep_merge!(hash_src, hash_dst, {:unpack_arrays => ","})
    hash_dst.should == {'region' => {'ids' => ["1", "2", "3", "4", "7", "--", "6", "8"], 'id'=>'11'}}
  end

  it "tests edge test 2: make sure that when we turn off source array split that all values are processed correctly" do
    hash_src = {"region" => {'ids' => ["7", "3", "--", "6,8"]}}
    hash_dst = {"region"=>{"ids"=>["1", "2", "3", "4"], 'id'=>'11'}}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {'region' => {'ids' => ["1", "2", "3", "4", "7", "--", "6,8"], 'id'=>'11'}}
  end

  it "tests Example: src = {'key' => \"--1\"}, dst = {'key' => \"1\"} -> merges to {'key' => \"\"}" do
    hash_src = {"amenity"=>"--1"}
    hash_dst = {"amenity"=>"1"}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {"amenity"=>""}
  end

  it "tests Example: src = {'key' => \"--1\"}, dst = {'key' => \"2\"} -> merges to {'key' => \"\"}" do
    hash_src = {"amenity"=>"--1"}
    hash_dst = {"amenity"=>"2"}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {"amenity"=>""}
  end

  it "tests Example: src = {'key' => \"--1\"}, dst = {'key' => \"1\"} -> merges to {'key' => \"\"}" do
    hash_src = {"amenity"=>["--1"]}
    hash_dst = {"amenity"=>"1"}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {"amenity"=>[]}
  end

  it "tests Example: src = {'key' => \"--1\"}, dst = {'key' => \"1\"} -> merges to {'key' => \"\"}" do
    hash_src = {"amenity"=>["--1"]}
    hash_dst = {"amenity"=>["1"]}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {"amenity"=>[]}
  end

  it "tests Example: src = {'key' => \"--1\"}, dst = {'key' => \"1\"} -> merges to {'key' => \"\"}" do
    hash_src = {"amenity"=>"--1"}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {"amenity"=>""}
  end

  it "tests Example: src = {'key' => \"--1\"}, dst = {'key' => \"1\"} -> merges to {'key' => \"\"}" do
    hash_src = {"amenity"=>"--1"}
    hash_dst = {"amenity"=>["1"]}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {"amenity"=>""}
  end

  it "tests are unmerged hashes passed unmodified w/out :unpack_arrays?" do
    hash_src = {"amenity"=>{"id"=>["26,27"]}}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix})
    hash_dst.should == {"amenity"=>{"id"=>["26,27"]}}
  end

  it "tests hash should be merged" do
    hash_src = {"amenity"=>{"id"=>["26,27"]}}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"amenity"=>{"id"=>["26","27"]}}
  end

  it "tests second merge of same values should result in no change in output" do
    hash_src = {"amenity"=>{"id"=>["26,27"]}}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"amenity"=>{"id"=>["26","27"]}}
  end

  it "tests hashes with knockout values are suppressed" do
    hash_src = {"amenity"=>{"id"=>["#{@field_ko_prefix}26,#{@field_ko_prefix}27,28"]}}
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => @field_ko_prefix, :unpack_arrays => ","})
    hash_dst.should == {"amenity"=>{"id"=>["28"]}}
  end

  it "unamed upstream - tbd" do
    hash_src= {'region' =>{'ids'=>['--']}, 'query_uuid' => 'zzz'}
    hash_dst= {'region' =>{'ids'=>['227','2','3','3']}, 'query_uuid' => 'zzz'}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {'region' =>{'ids'=>[]}, 'query_uuid' => 'zzz'}
  end

  it "unamed upstream - tbd" do
    hash_src= {'region' =>{'ids'=>['--']}, 'query_uuid' => 'zzz'}
    hash_dst= {'region' =>{'ids'=>['227','2','3','3'], 'id' => '3'}, 'query_uuid' => 'zzz'}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {'region' =>{'ids'=>[], 'id'=>'3'}, 'query_uuid' => 'zzz'}
  end

  it "unamed upstream - tbd" do
    hash_src= {'region' =>{'ids'=>['--']}, 'query_uuid' => 'zzz'}
    hash_dst= {'region' =>{'muni_city_id' => '2244', 'ids'=>['227','2','3','3'], 'id'=>'3'}, 'query_uuid' => 'zzz'}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {'region' =>{'muni_city_id' => '2244', 'ids'=>[], 'id'=>'3'}, 'query_uuid' => 'zzz'}
  end

  it "unamed upstream - tbd" do
    hash_src= {'region' =>{'ids'=>['--'], 'id' => '5'}, 'query_uuid' => 'zzz'}
    hash_dst= {'region' =>{'muni_city_id' => '2244', 'ids'=>['227','2','3','3'], 'id'=>'3'}, 'query_uuid' => 'zzz'}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {'region' =>{'muni_city_id' => '2244', 'ids'=>[], 'id'=>'5'}, 'query_uuid' => 'zzz'}
  end

  it "unamed upstream - tbd" do
    hash_src= {'region' =>{'ids'=>['--', '227'], 'id' => '5'}, 'query_uuid' => 'zzz'}
    hash_dst= {'region' =>{'muni_city_id' => '2244', 'ids'=>['227','2','3','3'], 'id'=>'3'}, 'query_uuid' => 'zzz'}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {'region' =>{'muni_city_id' => '2244', 'ids'=>['227'], 'id'=>'5'}, 'query_uuid' => 'zzz'}
  end

  it "unamed upstream - tbd" do
    hash_src= {'region' =>{'muni_city_id' => '--', 'ids'=>'--', 'id'=>'5'}, 'query_uuid' => 'zzz'}
    hash_dst= {'region' =>{'muni_city_id' => '2244', 'ids'=>['227','2','3','3'], 'id'=>'3'}, 'query_uuid' => 'zzz'}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {'region' =>{'muni_city_id' => '', 'ids'=>'', 'id'=>'5'}, 'query_uuid' => 'zzz'}
  end

  it "unamed upstream - tbd" do
    hash_src= {'region' =>{'muni_city_id' => '--', 'ids'=>['--'], 'id'=>'5'}, 'query_uuid' => 'zzz'}
    hash_dst= {'region' =>{'muni_city_id' => '2244', 'ids'=>['227','2','3','3'], 'id'=>'3'}, 'query_uuid' => 'zzz'}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {'region' =>{'muni_city_id' => '', 'ids'=>[], 'id'=>'5'}, 'query_uuid' => 'zzz'}
  end

  it "unamed upstream - tbd" do
    hash_src= {'region' =>{'muni_city_id' => '--', 'ids'=>['--','227'], 'id'=>'5'}, 'query_uuid' => 'zzz'}
    hash_dst= {'region' =>{'muni_city_id' => '2244', 'ids'=>['227','2','3','3'], 'id'=>'3'}, 'query_uuid' => 'zzz'}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {'region' =>{'muni_city_id' => '', 'ids'=>['227'], 'id'=>'5'}, 'query_uuid' => 'zzz'}
  end

  it "unamed upstream - tbd" do
    hash_src = {"muni_city_id"=>"--", "id"=>""}
    hash_dst = {"muni_city_id"=>"", "id"=>""}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {"muni_city_id"=>"", "id"=>""}
  end

  it "unamed upstream - tbd" do
    hash_src = {"region"=>{"muni_city_id"=>"--", "id"=>""}}
    hash_dst = {"region"=>{"muni_city_id"=>"", "id"=>""}}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {"region"=>{"muni_city_id"=>"", "id"=>""}}
  end

  it "unamed upstream - tbd" do
    hash_src = {"query_uuid"=>"a0dc3c84-ec7f-6756-bdb0-fff9157438ab", "url_regions"=>[], "region"=>{"muni_city_id"=>"--", "id"=>""}, "property"=>{"property_type_id"=>"", "search_rate_min"=>"", "search_rate_max"=>""}, "task"=>"search", "run_query"=>"Search"}
    hash_dst = {"query_uuid"=>"a0dc3c84-ec7f-6756-bdb0-fff9157438ab", "url_regions"=>[], "region"=>{"muni_city_id"=>"", "id"=>""}, "property"=>{"property_type_id"=>"", "search_rate_min"=>"", "search_rate_max"=>""}, "task"=>"search", "run_query"=>"Search"}
    @dm.deep_merge!(hash_src, hash_dst, {:knockout_prefix => '--', :unpack_arrays => ","})
    hash_dst.should == {"query_uuid"=>"a0dc3c84-ec7f-6756-bdb0-fff9157438ab", "url_regions"=>[], "region"=>{"muni_city_id"=>"", "id"=>""}, "property"=>{"property_type_id"=>"", "search_rate_min"=>"", "search_rate_max"=>""}, "task"=>"search", "run_query"=>"Search"}
  end

  it "tests hash of array of hashes" do
    hash_src = {"item" => [{"1" => "3"}, {"2" => "4"}]}
    hash_dst = {"item" => [{"3" => "5"}]}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"item" => [{"3" => "5"}, {"1" => "3"}, {"2" => "4"}]}
  end

  # Additions since import
  it "should overwrite true with false when merging boolean values" do
    hash_src = {"valid" => false}
    hash_dst = {"valid" => true}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"valid" => false}
  end

  it "should overwrite false with true when merging boolean values" do
    hash_src = {"valid" => true}
    hash_dst = {"valid" => false}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"valid" => true}
  end

  it "should overwrite a string with an empty string when merging string values" do
    hash_src = {"item" => " "}
    hash_dst = {"item" => "orange"}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"item" => " "}
  end

  it "should overwrite an empty string with a string when merging string values" do
    hash_src = {"item" => "orange"}
    hash_dst = {"item" => " "}
    @dm.deep_merge!(hash_src, hash_dst)
    hash_dst.should == {"item" => "orange"}
  end
end # deep_merge!

# Chef specific
describe Chef::Mixin::DeepMerge, "merge" do
  before do
    @dm = Chef::Mixin::DeepMerge
  end

  it "should merge a hash into an empty hash" do
    hash_dst = {}
    hash_src = {'id' => '2'}
    @dm.merge(hash_dst, hash_src).should == hash_src
  end

  it "should merge a nested hash into an empty hash" do
    hash_dst = {}
    hash_src = {'region' => {'id' => ['227', '2']}}
    @dm.merge(hash_dst, hash_src).should == hash_src
  end

  it "should overwrite as string value when merging hashes" do
    hash_dst = {"name" => "value1"}
    hash_src = {"name" => "value"}
    @dm.merge(hash_dst, hash_src).should == {"name" => "value"}
  end

  it "should merge arrays within hashes" do
    hash_dst = {"property" => ["2","4"]}
    hash_src = {"property" => ["1","3"]}
    @dm.merge(hash_dst, hash_src).should == {"property" => ["2","4","1","3"]}
  end

  it "should merge deeply nested hashes" do
    hash_dst = {"property" => {"values" => {"are" => "falling", "can" => "change"}}}
    hash_src = {"property" => {"values" => {"are" => "stable", "may" => "rise"}}}
    @dm.merge(hash_dst, hash_src).should == {"property" => {"values" => {"are" => "stable", "can" => "change", "may" => "rise"}}}
  end

  it "should knockout matching array value when merging arrays within hashes" do
    hash_dst = {"property" => ["2","4"]}
    hash_src = {"property" => ["1","!merge:4"]}
    @dm.merge(hash_dst, hash_src).should == {"property" => ["2","1"]}
  end

  it "should knockout all array values when merging arrays within hashes, leaving 2" do
    hash_dst = {"property" => ["2","4"]}
    hash_src = {"property" => ["!merge:","1","2"]}
    @dm.merge(hash_dst, hash_src).should == {"property" => ["1","2"]}
  end

  it "should knockout all array values when merging arrays within hashes, leaving 0" do
    hash_dst = {"property" => ["2","4"]}
    hash_src = {"property" => ["!merge:"]}
    @dm.merge(hash_dst, hash_src).should == {"property" => []}
  end
end
