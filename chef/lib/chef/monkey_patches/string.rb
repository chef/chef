# On ruby 1.9, Strings are aware of multibyte characters, so #size and length
# give the actual number of characters. In Chef::REST, we need the bytesize
# so we can correctly set the Content-Length headers, but ruby 1.8.6 and lower
# don't define String#bytesize. Monkey patching time!
class String
  unless method_defined?(:bytesize)
    alias :bytesize :size
  end
end
