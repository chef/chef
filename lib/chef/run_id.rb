require 'singleton'

class Chef
  class RunID
    include Singleton

    def reset_run_id
      @run_id = nil
    end

    def run_id
      @run_id ||= generate_run_id
    end

    def generate_run_id
      SecureRandom.uuid
    end
  end
end
