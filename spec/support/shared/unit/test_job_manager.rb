ObjectTestHarness = Proc.new do
  extend Shell::Extensions::ObjectCoreExtensions

  def conf=(new_conf)
    @conf = new_conf
  end

  def conf
    @conf
  end

  desc "rspecin'"
  def rspec_method; end
end

class TestJobManager
  attr_accessor :jobs
end
