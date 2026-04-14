module KnifeSpecs
  class TestYourself < Chef::Knife

    class << self
      attr_reader :test_deps_loaded
    end

    deps do
      @test_deps_loaded = true
    end

    option :scro, :short => '-s SCRO', :long => '--scro SCRO', :description => 'a configurable setting'

    attr_reader :ran

    def run
      @ran = true
      self # return self so tests can poke at me
    end
  end
end
