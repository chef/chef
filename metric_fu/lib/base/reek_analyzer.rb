# coding: utf-8

class ReekAnalyzer
  include ScoringStrategies

  REEK_ISSUE_INFO = {
    'Uncommunicative Name' =>
      {'link' => 'http://wiki.github.com/kevinrutherford/reek/uncommunicative-name',
       'info' => 'An Uncommunicative Name is a name that doesn’t communicate its intent well enough.'},
    'Class Variable' =>
      {'link' => 'http://wiki.github.com/kevinrutherford/reek/class-variable',
       'info' => 'Class variables form part of the global runtime state, and as such make it ' +
                 'easy for one part of the system to accidentally or inadvertently depend on ' +
                 'another part of the system.'},
    'Duplication' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/duplication',
       'info' => 'Duplication occurs when two fragments of code look nearly identical, or when ' +
                 'two fragments of code have nearly identical effects at some conceptual level.'},
    'Low Cohesion' =>
      {'link' => 'http://en.wikipedia.org/wiki/Cohesion_(computer_science)',
       'info' => 'Low cohesion is associated with undesirable traits such as being difficult to ' +
                 'maintain, difficult to test, difficult to reuse, and even difficult to understand.'},
    'Nested Iterators' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/nested-iterators',
       'info' => 'Nested Iterator occurs when a block contains another block.'},
    'Control Couple' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/control-couple',
       'info' => 'Control coupling occurs when a method or block checks the value of a parameter in ' +
                 'order to decide which execution path to take. The offending parameter is often called a “Control Couple”.'},
    'Irresponsible Module' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/irresponsible-module',
       'info' => 'Classes and modules are the units of reuse and release. It is therefore considered ' +
                 'good practice to annotate every class and module with a brief comment outlining its responsibilities.'},
    'Long Parameter List' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/long-parameter-list',
       'info' => 'A Long Parameter List occurs when a method has more than one or two parameters, ' +
                 'or when a method yields more than one or two objects to an associated block.'},
    'Data Clump' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/data-clump',
       'info' => 'In general, a Data Clump occurs when the same two or three items frequently appear ' +
                 'together in classes and parameter lists, or when a group of instance variable names ' +
                 'start or end with similar substrings.'},
    'Simulated Polymorphism' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/simulated-polymorphism',
       'info' => 'Simulated Polymorphism occurs when, code uses a case statement (especially on a ' +
                 'type field) or code uses instance_of?, kind_of?, is_a?, or === to decide what code to execute'},
    'Large Class' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/large-class',
       'info' => 'A Large Class is a class or module that has a large number of instance variables, ' +
                 'methods or lines of code in any one piece of its specification.'},
    'Long Method' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/long-method',
       'info' => 'Long methods can be hard to read and understand. They often are harder to test and ' +
                 'maintain as well, which can lead to buggier code.'},
    'Feature Envy' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/feature-envy',
       'info' => 'Feature Envy occurs when a code fragment references another object more often than ' +
                 'it references itself, or when several clients do the same series of manipulations ' +
                 'on a particular type of object.'},
    'Utility Function' =>
      {'link' =>'http://wiki.github.com/kevinrutherford/reek/utility-function',
       'info' => 'A Utility Function is any instance method that has no dependency on the state of the ' +
                 'instance. It reduces the code’s ability to communicate intent. Code that “belongs” on ' +
                 'one class but which is located in another can be hard to find.'},
    'Attribute' =>
      {'link' => 'http://wiki.github.com/kevinrutherford/reek/attribute',
       'info' => 'A class that publishes a getter or setter for an instance variable invites client ' +
                 'classes to become too intimate with its inner workings, and in particular with its ' +
                 'representation of state.'}
  }

  # Note that in practice, the prefix reek__ is appended to each one
  # This was a partially implemented idea to avoid column name collisions
  # but it is only done in the ReekAnalyzer
  COLUMNS = %w{type_name message value value_description comparable_message}

  def self.issue_link(issue)
    REEK_ISSUE_INFO[issue]
  end

  def columns
    COLUMNS.map{|column| "#{name}__#{column}"}
  end

  def name
    :reek
  end

  def map(row)
    ScoringStrategies.present(row)
  end

  def reduce(scores)
    ScoringStrategies.sum(scores)
  end

  def score(metric_ranking, item)
    ScoringStrategies.percentile(metric_ranking, item) 
  end

  def generate_records(data, table)
    return if data==nil
    data[:matches].each do |match|
      file_path = match[:file_path]
      match[:code_smells].each do |smell|
        location = MetricFu::Location.for(smell[:method])
        smell_type = smell[:type]
        message = smell[:message]
        table << {
          "metric" => name, # important
          "file_path" => file_path, # important
          # NOTE: ReekAnalyzer is currently different than other analyzers with regard
          # to column name. Note the COLUMNS constant and #columns method
          "reek__message" => message,
          "reek__type_name" => smell_type,
          "reek__value" => parse_value(message),
          "reek__value_description" => build_value_description(smell_type, message),
          "reek__comparable_message" => comparable_message(smell_type, message),
          "class_name" => location.class_name, # important
          "method_name" => location.method_name, # important
        }
      end
    end
  end

  def self.numeric_smell?(type)
    ["Large Class", "Long Method", "Long Parameter List"].include?(type)
  end

  private

  def comparable_message(type_name, message)
    if self.class.numeric_smell?(type_name)
      match = message.match(/\d+/)
      if(match)
        match.pre_match + match.post_match
      else
        message
      end
    else
      message
    end
  end

  def build_value_description(type_name, message)
    item_type = message.match(/\d+ (.*)$/)
    if(item_type)
      "number of #{item_type[1]} in #{type_name.downcase}"
    else
      nil
    end
  end

  def parse_value(message)
    match = message.match(/\d+/)
    if(match)
      match[0].to_i
    else
      nil
    end
  end

end
