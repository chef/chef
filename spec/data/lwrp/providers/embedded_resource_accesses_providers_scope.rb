# This action tests that embedded Resources have access to the enclosing Provider's
# lexical scope (as demonstrated by the call to new_resource) and that all parameters
# are passed properly (as demonstrated by the call to generate_new_name).
attr_reader :enclosed_resource

action :twiddle_thumbs do
  @enclosed_resource = lwrp_foo :foo do
    monkey generate_new_name(new_resource.monkey){ 'the monkey' }
    action :twiddle_thumbs
    provider :lwrp_monkey_name_printer
  end
end

def generate_new_name(str, &block)
  "#{str}, #{block.call}"
end
