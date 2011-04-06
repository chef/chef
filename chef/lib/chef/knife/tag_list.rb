require 'chef/knife'

class Chef
  class Knife
    class TagList < Knife

      deps do
        require 'chef/node'
      end

      banner "knife tag list NODE"

      def run
        name = @name_args[0]
        tags = @name_args[1..-1].join(",").split(/\s*,\s*/)

        unless name or tags.empty?
          show_usage
          # TODO: blah blah
          ui.fatal("You must specify a node name")
          exit 1
        end

        node = Chef::Node.load name
        output node.tags
      end
    end
  end
end
