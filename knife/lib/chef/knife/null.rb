class Chef
  class Knife
    class Null < Chef::Knife
      banner "knife null"

      # setting the category to deprecated keeps it out of help
      category "deprecated"

      def run; end
    end
  end
end
