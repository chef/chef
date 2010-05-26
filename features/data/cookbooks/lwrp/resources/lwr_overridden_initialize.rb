def initialize(name, run_context=nil)
  super
  puts "Overridden initialize"
end

actions :print_message

attribute :message, :kind_of => String
