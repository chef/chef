require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Table do

  context 'rows_with' do

    specify 'can select rows based on an optimized key (metric)' do
      table = Table.new(:column_names => %w{foo metric})
      table << {'metric' => 'flay', 'foo' => 1}
      table << {'metric' => 'flay', 'foo' => 2}
      table << {'metric' => 'flog', 'foo' => 1}
      table << {'metric' => 'saikuro', 'foo' => 2}
      matching_rows = table.rows_with(:metric => 'flay')
      matching_rows.length.should == 2
      matching_rows.each do |row|
        row.metric.should == 'flay'
      end
    end

    specify 'can select on arbitrary (non-optimized) field' do
      table = Table.new(:column_names => %w{foo baz})
      table << {'baz' => 'str1', 'foo' => 1}
      table << {'baz' => 'str2', 'foo' => 2}
      table << {'baz' => 'str3', 'foo' => 1}
      table << {'baz' => 'str4', 'foo' => 3}
      matching_rows = table.rows_with(:foo => 1)
      matching_rows.length.should == 2
      matching_rows.each do |row|
        row.foo.should == 1
      end

    end

  end

end
