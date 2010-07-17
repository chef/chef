attr_reader :monkey_name

action :twiddle_thumbs do
  @monkey_name = "my monkey's name is '#{new_resource.monkey}'"
end
