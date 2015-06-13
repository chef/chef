require 'decorator'

class Tracking
  attr_accessor :path

  include Decorator

  def path
    @path ||= []
  end

  def [](key)
    ret = wrapped_object[key]
    if ret.is_a? Enumerable
      new = self.class.new(ret)
      new.path = path + [key]
      new
    else
      ret
    end
  end
end
