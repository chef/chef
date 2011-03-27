#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2009, 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Knife
    class UI

      attr_reader :stdout
      attr_reader :stderr
      attr_reader :stdin
      attr_reader :config

      def initialize(stdout, stderr, stdin, config)
        @stdout, @stderr, @stdin, @config = stdout, stderr, stdin, config
      end

      def msg(message)
        stdout.puts message
      end

      alias :info :msg

      def warn(message)
        msg("WARNING: #{message}")
      end

      def ask_question(question, opts={})
        question = question + "[#{opts[:default]}] " if opts[:default]

        if opts[:default] and config[:defaults]
          opts[:default]
        else
          stdout.print question
          a = stdin.readline.strip

          if opts[:default]
            a.empty? ? opts[:default] : a
          else
            a
          end
        end
      end

      def pretty_print(data)
        stdout.puts data
      end

      def output(data)
        case config[:format]
        when "json", nil
          stdout.puts Chef::JSONCompat.to_json_pretty(data)
        when "yaml"
          require 'yaml'
          stdout.puts YAML::dump(data)
        when "text"
          # If you were looking for some attribute and there is only one match
          # just dump the attribute value
          if data.length == 1 and config[:attribute]
            stdout.puts data.values[0]
          else
            PP.pp(data, stdout)
          end
        else
          raise ArgumentError, "Unknown output format #{config[:format]}"
        end
      end

      def format_list_for_display(list)
        config[:with_uri] ? list : list.keys.sort { |a,b| a <=> b }
      end

      def format_for_display(item)
        data = item.kind_of?(Chef::DataBagItem) ? item.raw_data : item

        if config[:attribute]
          config[:attribute].split(".").each do |attr|
            if data.respond_to?(:[])
              data = data[attr]
            elsif data.nil?
              nil # don't get no method error on nil
            else data.respond_to?(attr.to_sym)
              data = data.send(attr.to_sym)
            end
          end
          { config[:attribute] => data.kind_of?(Chef::Node::Attribute) ? data.to_hash : data }
        elsif config[:run_list]
          data = data.run_list.run_list
          { "run_list" => data }
        elsif config[:environment]
          if data.class == Chef::Node
            {"chef_environment" => data.chef_environment}
          else
            # this is a place holder for now. Feel free to modify (i.e. add other cases). [nuo]
            data
          end
        elsif config[:id_only]
          data.respond_to?(:name) ? data.name : data["id"]
        else
          data
        end
      end

      def format_cookbook_list_for_display(item)
        if config[:with_uri]
          item
        else
          item.inject({}){|result, (k,v)|
            result[k] = v["versions"].inject([]){|res, ver| res.push(ver["version"]); res}
            result
          }
        end
      end

      def edit_data(data, parse_output=true)
        output = Chef::JSONCompat.to_json_pretty(data)

        if (!config[:no_editor])
          filename = "knife-edit-"
          0.upto(20) { filename += rand(9).to_s }
          filename << ".js"
          filename = File.join(Dir.tmpdir, filename)
          tf = File.open(filename, "w")
          tf.sync = true
          tf.puts output
          tf.close
          raise "Please set EDITOR environment variable" unless system("#{config[:editor]} #{tf.path}")
          tf = File.open(filename, "r")
          output = tf.gets(nil)
          tf.close
          File.unlink(filename)
        end

        parse_output ? Chef::JSONCompat.from_json(output) : output
      end

      def edit_object(klass, name)
        object = klass.load(name)

        output = edit_data(object)

        # Only make the save if the user changed the object.
        #
        # Output JSON for the original (object) and edited (output), then parse
        # them without reconstituting the objects into real classes
        # (create_additions=false). Then, compare the resulting simple objects,
        # which will be Array/Hash/String/etc.
        #
        # We wouldn't have to do these shenanigans if all the editable objects
        # implemented to_hash, or if to_json against a hash returned a string
        # with stable key order.
        object_parsed_again = Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(object), :create_additions => false)
        output_parsed_again = Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(output), :create_additions => false)
        if object_parsed_again != output_parsed_again
          output.save
          self.msg("Saved #{output}")
        else
          self.msg("Object unchanged, not saving")
        end
        output(format_for_display(object)) if config[:print_after]
      end

      def confirm(question, append_instructions=true)
        return true if config[:yes]

        stdout.print question
        stdout.print "? (Y/N) " if append_instructions
        answer = stdin.readline
        answer.chomp!
        case answer
        when "Y", "y"
          true
        when "N", "n"
          self.msg("You said no, so I'm done here.")
          exit 3
        else
          self.msg("I have no idea what to do with #{answer}")
          self.msg("Just say Y or N, please.")
          confirm(question)
        end
      end

    end
  end
end
