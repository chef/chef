def load_current_resource
  puts "Overridden load_current_resource"
end

action :print_message do
  puts new_resource.message
end

