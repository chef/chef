def initialize(name, collection=nil, node=nil)
  super(name, collection, node)
  puts "Overridden initialize"
end

actions :print_message

attribute :message, :kind_of => String
