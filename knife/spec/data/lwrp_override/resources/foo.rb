# Starting with Chef 12 reloading an LWRP shouldn't reload the file anymore
unified_mode true

actions :never_execute

attribute :ever, :kind_of => String

class ::Chef
  def method_created_by_override_lwrp_foo
  end
end
