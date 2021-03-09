# This action tests that embedded Resources have access to the enclosing Provider's
# lexical scope (as demonstrated by the call to new_resource) and that all parameters
# are passed properly (as demonstrated by the call to generate_new_name).
attr_reader :enclosed_resource

def without_deprecation_warnings(&block)
  old_treat_deprecation_warnings_as_errors = Chef::Config[:treat_deprecation_warnings_as_errors]
  Chef::Config[:treat_deprecation_warnings_as_errors] = false
  begin
    yield
  ensure
    Chef::Config[:treat_deprecation_warnings_as_errors] = old_treat_deprecation_warnings_as_errors
  end
end

def action_twiddle_thumbs
  @enclosed_resource = lwrp_foo :foo do
    monkey generate_new_name(new_resource.monkey){ 'the monkey' }
    # We know there will be a deprecation error here; head it off
    without_deprecation_warnings do
      provider :lwrp_monkey_name_printer
    end
  end
end

def generate_new_name(str, &block)
  "#{str}, #{block.call}"
end
