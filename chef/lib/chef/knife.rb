#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'mixlib/cli'
require 'chef/mixin/convert_to_class_name'

class Chef
  class Knife
    include Mixlib::CLI
    extend Chef::Mixin::ConvertToClassName

    attr_accessor :name_args

    # Load all the sub-commands
    def self.load_commands
      @sub_classes = Hash.new
      Dir[
        File.expand_path(File.join(File.dirname(__FILE__), 'knife', '*.rb'))
      ].each do |knife_file|
        require knife_file
        snake_case_file_name = File.basename(knife_file).sub(/\.rb$/, '')
        @sub_classes[snake_case_file_name] = convert_to_class_name(snake_case_file_name)
      end
      @sub_classes
    end

    def self.list_commands
      load_commands
      @sub_classes.keys.sort.each do |snake_case|
        klass_instance = build_sub_class(snake_case) 
        klass_instance.parse_options
        puts klass_instance.opt_parser
        puts
      end
    end

    def self.build_sub_class(snake_case, merge_opts=nil)
      klass = Chef::Knife.const_get(@sub_classes[snake_case])
      klass.options.merge!(merge_opts) if merge_opts 
      klass.new
    end

    def self.find_command(args=ARGV, merge_opts={})
      load_commands

      non_dash_args = Array.new
      args.each do |arg|
        non_dash_args << arg if arg =~ /^([[:alnum:]]|_)+$/
      end

      to_try = non_dash_args.length 
      klass_instance = nil
      cli_bits = nil 

      while(to_try >= 0)
        cli_bits = non_dash_args[0..to_try]
        snake_case_class_name = cli_bits.join("_")

        if @sub_classes.has_key?(snake_case_class_name)
          klass_instance = build_sub_class(snake_case_class_name, merge_opts)
          break
        end

        to_try = to_try - 1
      end

      unless klass_instance
        Chef::Log.fatal("Cannot find sub command for: #{args.join(' ')}")
        Chef::Knife.list_commands
        exit 10
      end

      extra = klass_instance.parse_options(args)
      if klass_instance.config[:help]
        puts klass_instance.opt_parser
        exit 1
      end
      klass_instance.name_args = extra.inject([]) { |c, i| cli_bits.include?(i) ? cli_bits.delete(i) : c << i; c } 
      klass_instance.configure_chef
      klass_instance
    end

    def ask_question(q)
      print q 
      a = STDIN.readline
      a.chomp!
      a
    end

    def configure_chef
      if !config[:config_file].nil? && File.exists?(config[:config_file]) && File.readable?(config[:config_file])
        Chef::Config.from_file(config[:config_file]) 
      end

      Chef::Config[:log_level] = config[:log_level] if config[:log_level]
      Chef::Config[:log_location] = config[:log_location] if config[:log_location]
      Chef::Config[:node_name] = config[:node_name] if config[:node_name]
      Chef::Config[:client_key] = config[:client_key] if config[:client_key]
      Chef::Config[:chef_server_url] = config[:chef_server_url] if config[:chef_server_url]
      Mixlib::Log::Formatter.show_time = false
      Chef::Log.init(Chef::Config[:log_location])
      Chef::Log.level(Chef::Config[:log_level])

      if Chef::Config[:node_name].nil?
        raise ArgumentError, "No user specified, pass via -u or specifiy 'node_name' in #{config[:config_file] ? config[:config_file] : "~/.chef/knife.rb"}"
      end
    end

    def pretty_print(data)
      puts data
    end

    def json_pretty_print(data)
      puts JSON.pretty_generate(data)
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
          else
            data = data.send(attr.to_sym)
          end
        end
        { config[:attribute] => data.kind_of?(Chef::Node::Attribute) ? data.to_hash: data }
      elsif config[:run_list]
        data = data.run_list.run_list
        { "run_list" => data }
      elsif config[:id_only]
        data.respond_to?(:name) ? data.name : data["id"]
      else
        data
      end
    end

    def edit_data(data, parse_output=true)
      output = JSON.pretty_generate(data)
      
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

      parse_output ? JSON.parse(output) : output
    end

    def confirm(question)
      return true if config[:yes]

      print "#{question}? (Y/N) "
      answer = STDIN.readline
      answer.chomp!
      case answer
      when "Y", "y"
        true
      when "N", "n"
        Chef::Log.info("You said no, so I'm done here.")
        exit 3 
      else
        Chef::Log.error("I have no idea what to do with #{answer}")
        Chef::Log.error("Just say Y or N, please.")
        confirm(question)
      end
    end

    def load_from_file(klass, from_file) 
      from_file = @name_args[0]
      relative_file = File.expand_path(File.join(Dir.pwd, 'roles', from_file))
      filename = nil

      if file_exists_and_is_readable?(from_file)
        filename = from_file
      elsif file_exists_and_is_readable?(relative_file) 
        filename = relative_file 
      else
        Chef::Log.fatal("Cannot find file #{from_file}")
        exit 30
      end

      case from_file
      when /\.(js|json)$/
        JSON.parse(IO.read(filename))
      when /\.rb$/
        r = klass.new
        r.from_file(filename)
        r
      else
        Chef::Log.fatal("File must end in .js, .json, or .rb")
        exit 30
      end
    end

    def file_exists_and_is_readable?(file)
      File.exists?(file) && File.readable?(file)
    end

    def edit_object(klass, name)
      object = klass.load(name)

      output = edit_data(object)
      
      output.save

      Chef::Log.info("Saved #{output}")

      json_pretty_print(format_for_display(object)) if config[:print_after]
    end

    def create_object(object, pretty_name=nil, &block)
      output = edit_data(object)

      if Kernel.block_given?
        output = block.call(output)
      else
        output.save
      end

      pretty_name ||= output

      Chef::Log.info("Created (or updated) #{pretty_name}")
      
      json_pretty_print(output) if config[:print_after]
    end

    def delete_object(klass, name, delete_name=nil, &block)
      confirm("Do you really want to delete #{name}")

      if Kernel.block_given?
        object = block.call
      else
        object = klass.load(name)
        object.destroy
      end

      json_pretty_print(format_for_display(object)) if config[:print_after]

      obj_name = delete_name ? "#{delete_name}[#{name}]" : object
      Chef::Log.warn("Deleted #{obj_name}!")
    end

    def bulk_delete(klass, fancy_name, delete_name=nil, list=nil, regex=nil, &block)
      object_list = list ? list : klass.list(true)

      if regex
        to_delete = Hash.new
        object_list.each_key do |object|
          next if regex && object !~ /#{regex}/
          to_delete[object] = object_list[object]
        end
      else
        to_delete = object_list
      end

      json_pretty_print(format_list_for_display(to_delete))

      confirm("Do you really want to delete the above items")

      to_delete.each do |name, object|
        if Kernel.block_given?
          block.call(name, object)
        else
          object.destroy
        end
        json_pretty_print(format_for_display(object)) if config[:print_after]
        Chef::Log.warn("Deleted #{fancy_name} #{name}")
      end
    end

    def rest
      @rest ||= Chef::REST.new(Chef::Config[:chef_server_url])
    end

  end
end

