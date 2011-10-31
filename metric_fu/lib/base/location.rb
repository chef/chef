module MetricFu
  class Location
    include Comparable

    attr_accessor :class_name, :method_name, :file_path, :simple_method_name, :hash

    def self.get(file_path, class_name, method_name)
      # This could be more 'confident' using Maybe, but we want it to be as fast as possible
      file_path_copy = file_path == nil ? nil : file_path.clone
      class_name_copy = class_name == nil ? nil : class_name.clone
      method_name_copy = method_name == nil ? nil : method_name.clone
      key = [file_path_copy, class_name_copy, method_name_copy]
      @@locations ||= {}
      if @@locations.has_key?(key)
        @@locations[key]
      else
        location = self.new(file_path_copy, class_name_copy, method_name_copy)
        @@locations[key] = location
        location.freeze  # we cache a lot of method call results, so we want location to be immutable
        location
      end
    end

    def initialize(file_path, class_name, method_name)
      @file_path = file_path
      @class_name = class_name
      @method_name = method_name
      @simple_method_name = @method_name.sub(@class_name,'') unless @method_name == nil
      @hash = [@file_path, @class_name, @method_name].hash
    end

    # TODO - we need this method (and hash accessor above) as a temporary hack where we're using Location as a hash key
    def eql?(other)
      [self.file_path.to_s, self.class_name.to_s, self.method_name.to_s] == [other.file_path.to_s, other.class_name.to_s, other.method_name.to_s]
    end
    # END we need these methods as a temporary hack where we're using Location as a hash key

    def self.for(class_or_method_name)
      class_or_method_name = strip_modules(class_or_method_name)
      if(class_or_method_name)
        begin
          match = class_or_method_name.match(/(.*)((\.|\#|\:\:[a-z])(.+))/)
        rescue => error
          #new error during port to metric_fu occasionally a unintialized
          #MatchData object shows up here. Not expected.
          match = nil
        end

        # reek reports the method with :: not # on modules like
        # module ApplicationHelper \n def signed_in?, convert it so it records correctly
        # but classes have to start with a capital letter... HACK for REEK bug, reported underlying issue to REEK
        if(match)
          class_name = strip_modules(match[1])
          method_name = class_or_method_name.gsub(/\:\:/,"#")
        else
          class_name = strip_modules(class_or_method_name)
          method_name = nil
        end
      else
        class_name = nil
        method_name = nil
      end
      self.get(nil, class_name, method_name)
    end

    def <=>(other)
      [self.file_path.to_s, self.class_name.to_s, self.method_name.to_s] <=> [other.file_path.to_s, other.class_name.to_s, other.method_name.to_s]
    end

    private

    def self.strip_modules(class_or_method_name)
      # reek reports the method with :: not # on modules like 
      # module ApplicationHelper \n def signed_in?, convert it so it records correctly
      # but classes have to start with a capital letter... HACK for REEK bug, reported underlying issue to REEK
      if(class_or_method_name=~/\:\:[A-Z]/)
        class_or_method_name.split("::").last
      else
        class_or_method_name
      end

    end

  end
end
