# Adds a Dir.glob to Ruby 1.8.5, for compat
if RUBY_VERSION < "1.8.6" || RUBY_PLATFORM =~ /mswin|mingw32|windows/
  class Dir 
    class << self 
      alias_method :glob_, :glob 
      def glob(pattern, flags=0)
        raise ArgumentError unless (
          !pattern.nil? and (
            pattern.is_a? Array and !pattern.empty?
          ) or pattern.is_a? String
        )
        pattern.gsub!(/\\/, "/") if RUBY_PLATFORM =~ /mswin|mingw32|windows/
        [pattern].flatten.inject([]) { |r, p| r + glob_(p, flags) }
      end
      alias_method :[], :glob 
    end 
  end 
end 
