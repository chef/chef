#--
# Copyright:: Copyright 2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "delegate"

class Chef
  class Decorator < SimpleDelegator
    NULL = ::Object.new

    def initialize(obj = NULL)
      @__defined_methods__ = []
      super unless obj.equal?(NULL)
    end

    # if we wrap a nil then decorator.nil? should be true
    def nil?
      __getobj__.nil?
    end

    # if we wrap a Hash then decorator.is_a?(Hash) should be true
    def is_a?(klass)
      __getobj__.is_a?(klass) || super
    end

    # if we wrap a Hash then decorator.kind_of?(Hash) should be true
    def kind_of?(klass)
      __getobj__.kind_of?(klass) || super
    end

    # reset our methods on the instance if the object changes under us (this also
    # clears out the closure over the target we create in method_missing below)
    def __setobj__(obj)
      __reset_methods__
      super
    end

    # this is the ruby 2.2/2.3 implementation of Delegator#method_missing() with
    # adding the define_singleton_method call and @__defined_methods__ tracking
    def method_missing(m, *args, &block)
      r = true
      target = __getobj__ { r = false }

      if r && target.respond_to?(m)
        # these next 4 lines are the patched code
        define_singleton_method(m) do |*args, &block|
          target.__send__(m, *args, &block)
        end
        @__defined_methods__.push(m)
        target.__send__(m, *args, &block)
      elsif ::Kernel.respond_to?(m, true)
        ::Kernel.instance_method(m).bind(self).call(*args, &block)
      else
        super(m, *args, &block)
      end
    end

    private

    # used by __setobj__ to clear the methods we've built on the instance.
    def __reset_methods__
      @__defined_methods__.each do |m|
        singleton_class.send(:undef_method, m)
      end
      @__defined_methods__ = []
    end
  end
end
