module EnvironmentsHelper
  def cookbook_version_constraints
    @environment.cookbook_versions.inject({}) do |ans, (cb, vc)|
      op, version = vc.split(" ")
      ans[cb] = { "version" => version, "op" => op }
      ans
    end
  end

  def constraint_operators
    %w(~> >= > = < <=)
  end
end