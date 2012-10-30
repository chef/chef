class Object
  unless new.respond_to?(:tap)
    def tap
      yield self
      return self
    end
  end
end

