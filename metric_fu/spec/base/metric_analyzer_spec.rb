require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe MetricAnalyzer do

  context "with several types of data" do
    
    before do
      @yaml =<<-__
--- 
:reek: 
  :matches: 
  - :file_path: lib/client/client.rb
    :code_smells: 
    - :type: Large Class
      :message: has at least 27 methods
      :method: Devver::Client
    - :type: Long Method
      :message: has approx 6 statements
      :method: Devver::Client#client_requested_sync
:flog: 
  :method_containers: 
  - :highest_score: 61.5870319141946
    :path: /lib/client/client.rb
    :methods: 
      Client#client_requested_sync: 
        :path: /lib/client/client.rb
        :score: 37.9270319141946
        :operators: 
          :+: 1.70000000000001
          :/: 1.80000000000001
          :method_at_line: 1.90000000000001
          :puts: 1.70000000000001
          :assignment: 33.0000000000001
          :in_method?: 1.70000000000001
          :message: 1.70000000000001
          :branch: 12.6
          :<<: 3.40000000000001
          :each: 1.50000000000001
          :lit_fixnum: 1.45
          :raise: 1.80000000000001
          :each_pair: 1.3
          :*: 1.60000000000001
          :to_f: 2.00000000000001
          :each_with_index: 3.00000000000001
          :[]: 22.3000000000001
          :new: 1.60000000000001
    :average_score: 11.1209009055421
    :total_score: 1817.6
    :name: Client#client_requested_sync
:churn: 
  :changes: 
  - :file_path: lib/client/client.rb
    :times_changed: 54
  - :file_path: lib/client/foo.rb
    :times_changed: 52
__
    end

    it "gives all files, in order, from worst to best" do 
      analyzer = MetricAnalyzer.new(@yaml)
      expected = [
                  "lib/client/client.rb",
                  "lib/client/foo.rb"]
      analyzer.worst_files.should == expected
    end

    it "gives all issues for a class" do
      analyzer = MetricAnalyzer.new(@yaml)
      expected = {
        :reek => "found 2 code smells",
        :flog => "complexity is 37.9"
      }
      analyzer.problems_with(:class, "Client").should == expected
    end

    it "gives all issues for a method" do
      analyzer = MetricAnalyzer.new(@yaml)
      expected = { 
        :reek => "found 1 code smells", 
        :flog => "complexity is 37.9"}
      analyzer.problems_with(:method, "Client#client_requested_sync").should == expected
    end

    it "gives all issues for a file" do
      analyzer = MetricAnalyzer.new(@yaml)
      expected = { 
        :reek => "found 2 code smells" ,
        :flog => "complexity is 37.9",
        :churn => "detected high level of churn (changed 54 times)"}
      analyzer.problems_with(:file, "lib/client/client.rb").should == expected
    end

    it "provide location for a method" do
      analyzer = MetricAnalyzer.new(@yaml)
      expected = Location.new("lib/client/client.rb",
                              "Client",
                              "Client#client_requested_sync")
      analyzer.location(:method, "Client#client_requested_sync").should == expected
    end

    it "provides location for a class" do
      analyzer = MetricAnalyzer.new(@yaml)
      expected = Location.new("lib/client/client.rb",
                              "Client",
                              nil)
      analyzer.location(:class, "Client").should == expected
    end

    it "provides location for a file" do
      analyzer = MetricAnalyzer.new(@yaml)
      expected = Location.new("lib/client/client.rb",
                              nil,
                              nil)
      analyzer.location(:file, "lib/client/client.rb").should == expected
    end

  end

  context "with Reek data" do

    before do
      @yaml =<<-__
--- 
:reek: 
  :matches: 
  - :file_path: lib/client/client.rb
    :code_smells: 
    - :type: Large Class
      :message: has at least 27 methods
      :method: Devver::Client
    - :type: Long Method
      :message: has approx 6 statements
      :method: Devver::Client#client_requested_sync
    - :type: Large Class
      :message: has at least 20 methods
      :method: Devver::Foo
__
    end

    it "gives worst method" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_methods(1).should == ["Client#client_requested_sync"]
    end

    it "gives worst class" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_classes(1).should == ["Client"]
    end

    it "gives worst file" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_files(1).should == ["lib/client/client.rb"]
    end

  end


  context "with Saikuro data" do
    
    before do
      @yaml =<<-__
:saikuro: 
  :files: 
  - :classes: 
    - :complexity: 0
      :methods: []
      :lines: 3
      :class_name: Shorty
    - :complexity: 19
      :methods: 
      - :complexity: 9
        :lines: 6
        :name: Shorty::Supr#self.handle_full_or_hash_option
      - :complexity: 1
        :lines: 9
        :name: Shorty::Supr#initialize
      :lines: 92
      :class_name: Shorty::Supr
    :filename: supr.rb
  - :classes: 
    - :complexity: 12
      :methods: 
      - :complexity: 8
        :lines: 10
        :name: Shorty::Bitly#info
      :lines: 104
      :class_name: Shorty::Bitly
    :filename: bitly.rb
__
    end
    
    it "gives worst method" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_methods(1).should == ["Supr#self.handle_full_or_hash_option"]
    end

    it "gives worst class" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_classes(1).should == ["Bitly"]
    end

    it "gives complexity for method" do
      analyzer = MetricAnalyzer.new(@yaml)
      expected = {
        :saikuro => "complexity is 1.0"
      }
      analyzer.problems_with(:method, "Supr#initialize").should == expected
    end
    
    it "gives average complexity for class" do
      analyzer = MetricAnalyzer.new(@yaml)
      expected = {
        :saikuro => "average complexity is 5.0"
      }
      analyzer.problems_with(:class, "Supr").should == expected
    end

  end

  context "with Flog data" do
    
    before do
      @yaml =<<-__
--- 
:flog: 
  :method_containers: 
  - :highest_score: 85.5481735632041
    :path: ""
    :methods: 
      main#none: 
        :path: 
        :score: 85.5481735632041
        :operators: 
          :+: 9.10000000000001
          :assignment: 11.6000000000001
          :require: 38.5000000000002
          :branch: 8.80000000000009
          :join: 20.0000000000002
          :each: 6.60000000000007
          :[]: 7.80000000000007
          :task_defined?: 1.10000000000001
          :load: 1.20000000000001
    :average_score: 85.5481735632041
    :total_score: 85.5481735632041
    :name: main
  - :highest_score: 61.5870319141946
    :path: lib/generators/rcov.rb
    :methods: 
      Rcov#add_method_data: 
        :path: lib/generators/rcov.rb:57
        :score: 61.5870319141946
        :operators: 
          :+: 1.70000000000001
          :/: 1.80000000000001
          :method_at_line: 1.90000000000001
          :puts: 1.70000000000001
          :assignment: 33.0000000000001
          :in_method?: 1.70000000000001
          :message: 1.70000000000001
          :branch: 12.6
          :<<: 3.40000000000001
          :each: 1.50000000000001
          :lit_fixnum: 1.45
          :raise: 1.80000000000001
          :each_pair: 1.3
          :*: 1.60000000000001
          :to_f: 2.00000000000001
          :each_with_index: 3.00000000000001
          :[]: 22.3000000000001
          :new: 1.60000000000001
      Rcov#analyze: 
        :path: lib/generators/rcov.rb:34
        :score: 19.1504569136092
        :operators: 
          :+: 1.40000000000001
          :metric_directory: 1.6
          :assignment: 9.10000000000004
          :assemble_files: 1.3
          :branch: 1.3
          :open: 1.5
          :shift: 1.3
          :split: 1.3
          :rcov: 3.10000000000001
          :add_coverage_percentage: 1.3
          :read: 1.3
          :[]: 2.70000000000001
  :average_score: 27.8909176873585
  :total_score: 195.23642381151
  - :highest_score: 60.0573892206447
    :path: lib/base/metric_analyzer.rb
    :methods: 
      MetricAnalyzer#grouping_key: 
        :path: lib/base/metric_analyzer.rb:117
        :score: 2.6
        :operators: 
          :inspect: 1.3
          :object_id: 1.3
      MetricAnalyzer#fix_row_file_path!: 
        :path: lib/base/metric_analyzer.rb:148
        :score: 20.2743680542699
        :operators: 
          :assignment: 10.0
          :include?: 3.1
          :branch: 7.20000000000001
          :detect: 1.5
          :file_paths: 1.7
          :==: 3.1
          :to_s: 1.3
          :[]: 5.40000000000001
__
    end
    
    it "gives worst method" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_methods(1).should == ["main#none"]
    end

    it "gives worst class" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_classes(1).should == ["main"]
    end

    it "gives worst file" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_files(1).should == ["lib/generators/rcov.rb:57"]
    end

  end

  context "with Roodi data" do
    
    before do
      @yaml =<<-__
:roodi: 
  :total: 
  - Found 164 errors.
  :problems: 
  - :line: "158"
    :file: lib/client/client.rb
    :problem: Method name "process" cyclomatic complexity is 10.  It should be 8 or less.
  - :line: "232"
    :file: lib/client/client.rb
    :problem: Method name "process_ready" cyclomatic complexity is 15.  It should be 8 or less.
  - :line: "288"
    :file: lib/client/foobar.rb
    :problem: Method name "send_tests" cyclomatic complexity is 10.  It should be 8 or less.
__
    end

    it "gives worst file" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.worst_files(1).should == ["lib/client/client.rb"]
    end

  end

  context "with Stats data" do
    
    before do
 @yaml =<<-__
:stats: 
  :codeLOC: 4222
  :testLOC: 2111
  :code_to_test_ratio: 2
__
end
    
    it "should have codeLOC" do
      analyzer = MetricAnalyzer.new(@yaml)
      row = analyzer.table.rows_with('stat_name' => :codeLOC).first
      row['stat_value'].should == 4222
    end

    it "should have testLOC" do
      analyzer = MetricAnalyzer.new(@yaml)
      row = analyzer.table.rows_with('stat_name' => :testLOC).first
      row['stat_value'].should == 2111
    end

    it "should have code_to_test_ration" do
      analyzer = MetricAnalyzer.new(@yaml)
      row = analyzer.table.rows_with('stat_name' => :code_to_test_ratio).first
      row['stat_value'].should == 2
    end

  end

  context "with three different path representations of file (from Saikuro, Flog, and Reek)" do

        before do
      @yaml =<<-__
:saikuro: 
  :files: 
  - :classes: 
    - :complexity: 19
      :methods: 
      - :complexity: 1
        :lines: 9
        :name: Client#client_requested_sync
      - :complexity: 1
        :lines: 9
        :name: Client#method_that_is_not_mentioned_elsewhere_in_stats
      :lines: 92
      :class_name: Devver::Client
    :filename: client.rb
:reek: 
  :matches: 
  - :file_path: lib/client/client.rb
    :code_smells: 
    - :type: Large Class
      :message: has at least 27 methods
      :method: Devver::Client
    - :type: Long Method
      :message: has approx 6 statements
      :method: Devver::Client#client_requested_sync
:flog: 
  :total: 1817.6
  :pages: 
  - :path: /lib/client/client.rb
    :highest_score: 37.9
    :average_score: 13.6
    :scanned_methods: 
    - :operators: 
      - :operator: "[]"
        :score: 11.1
      :score: 37.9
      :name: Client#client_requested_sync
__
    end

    specify "all records should have full file_path" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.table.each do |row|
        row['file_path'].should == 'lib/client/client.rb'
      end
    end
    
    specify "all records should have class name" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.table.rows_with(:class_name => nil).should have(0).rows
    end

    specify "one record should not have method name" do
      analyzer = MetricAnalyzer.new(@yaml)
      analyzer.table.rows_with(:method_name => nil).should have(1).rows
    end

  end

end


