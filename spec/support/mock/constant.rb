# Allows easy mocking of global and class constants

# Inspired by:
# http://missingbit.blogspot.com/2011/07/stubbing-constants-in-rspec_20.html
# http://digitaldumptruck.jotabout.com/?p=551

def mock_constants(constants, &block)
  saved_constants = {}
  constants.each do |constant, val|
    source_object, const_name = parse_constant(constant)
    saved_constants[constant] = source_object.const_get(const_name)
    with_warnings(nil) {source_object.const_set(const_name, val) }
  end

  begin
    block.call
  ensure
    constants.each do |constant, val|
      source_object, const_name = parse_constant(constant)
      with_warnings(nil) { source_object.const_set(const_name, saved_constants[constant]) }
    end
  end
end

def parse_constant(constant)
  source, _, constant_name = constant.to_s.rpartition('::')
  [constantize(source), constant_name]
end

# Taken from ActiveSupport

# File activesupport/lib/active_support/core_ext/kernel/reporting.rb, line 3
#
# Sets $VERBOSE for the duration of the block and back to its original value afterwards.
def with_warnings(flag)
  old_verbose, $VERBOSE = $VERBOSE, flag
  yield
ensure
  $VERBOSE = old_verbose
end

# File activesupport/lib/active_support/inflector/methods.rb, line 209
def constantize(camel_cased_word)
  names = camel_cased_word.split('::')
  names.shift if names.empty? || names.first.empty?

  constant = Object
  names.each do |name|
    constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
  end
  constant
end
