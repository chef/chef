require 'chef/event_dispatch/base'

class Chef
    module Logging
        class EventLogger < EventDispatch::Base
        end
    end
end
