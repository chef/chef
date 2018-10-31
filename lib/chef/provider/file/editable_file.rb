#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2018, Chef Software Inc.
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
  class Provider
    class File < Chef::Provider
      class EditableFile
        # String path to the file
        attr_accessor :path

        # Array<String> lines in the file
        attr_accessor :file_contents

        # Hash<String> dictionary of location objects by name
        def locations
          @locations ||= {}
        end

        # Hash<String> dictionary of region objects by name
        def regions
          @regions ||= {}
        end

        class Location
          attr_accessor :name
          attr_accessor :editable_file

          def initialize(editable_file, name)
            @editable_file = editable_file
            @name = name
            @before = false
            @first = false
            @match = /.*/
          end

          def before(arg = nil)
            @before = !!arg unless arg.nil?
            @before
          end

          def after(arg = nil)
            @before = !arg unless arg.nil?
            !@before
          end

          def first(arg = nil)
            @first = !!arg unless arg.nil?
            @first
          end

          def last(arg = nil)
            @first = !arg unless arg.nil?
            !@first
          end

          def match(pattern = nil)
            if pattern
              @match = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
            end
            @match
          end

          def index
            iterator = ( first ) ? :each : :reverse_each
            editable_file.file_contents.send(iterator).with_index do |line, i|
              i = ( first ) ? i : editable_file.file_contents.length - i - 1
              if match.match?(line)
                return before ? i : i + 1
              end
            end
            raise "match not found" # FIXME: better error
          end
        end

        class Region
          attr_accessor :name
          def initialize(name)
            @name = name
          end
        end

        def empty!
          @file_contents = []
        end

        def initialize(file_contents, path)
          @file_contents = file_contents
          @path = path
        end

        def self.from_file(path)
          new(::File.readlines(path), path)
        end

        def self.from_string(string, path_out)
          new(string.lines, path_out)
        end

        def self.from_array(array, path_out)
          new(array, path_out)
        end

        # @param lines [ String, IO, Array<String> ] source of the lines to insert
        # @param ignore_leading [ Boolean ] ignore leading whitespace in the idempotency check
        # @param ignore_trailing [ Boolean ] ignore traliing whitespece in the idempotency check
        # @param ignore_embedded [ Boolean ] ignore embedded whitespace in the idempotency check
        # @param idempotency [ Boolean ] set to false to ignore the idempotency check entirely
        # FIXME: @param preserve_block [ Boolean ] if `what` is multi-line treat it as a block of lines, not individual lines
        # FIXME: insert_select support for files?
        def insert(lines, location:, ignore_leading: false, ignore_trailing: false, ignore_embedded: false, idempotency: true) # , preserve_block: false)
          raise "no such location" unless locations.key?(location) # FIXME: better errors
          lines = lines.read if lines.is_a?(IO)
          lines = lines.lines if lines.is_a?(String)
          lines = Array( lines )
          lines.each do |line|
            if idempotency
              regexp = generate_regexp(line, ignore_leading: ignore_leading, ignore_trailing: ignore_trailing, ignore_embedded: ignore_embedded)
              next if file_contents.any? { |l| l.match?(regexp) }
            end
            idx = locations[location].index
            file_contents.insert(idx, line + "\n")
          end
        end

        # FIXME: delete_select support for files?
        def delete(lines, ignore_leading: false, ignore_trailing: false, ignore_embedded: false, not_matching: false)
          lines = lines.read if lines.is_a?(IO)
          lines = lines.lines if lines.is_a?(String)
          lines = Array( lines )
          lines.each do |line|
            regexp =
              if line.is_a?(Regexp)
                line
              else
                generate_regexp(line, ignore_leading: ignore_leading, ignore_trailing: ignore_trailing, ignore_embedded: ignore_embedded)
              end
            file_contents.reject! { |line| not_matching ? !regexp.match?(line) : regexp.match?(line) }
          end
        end

        def replace(regexp, with)
          file_contents.map! { |line| line.gsub!(regexp, with) }
        end

        # @return <Location> the new location object
        def location(name, &block)
          l = Location.new(self, name)
          l.instance_exec(&block) if block_given?
          locations[name] = l
        end

        # @return <Region> the new region object
        def region(name, &block)
          r = Region.new(name)
          r.instance_exec(&block) if block_given?
          regions[name] = r
        end

        def finish!
          ::File.open(path, "w") do |f|
            f.write file_contents.join
          end
        end

        def use(klass, method)
          p = klass.instance_method(method)
          instance_eval(&p)
        end

        private

        def generate_regexp(string, ignore_leading: false, ignore_trailing: false, ignore_embedded: false)
          escaped =
            if ignore_embedded
              string.split(/\s+/).map { |s| Regexp.escape(s) }.join('\s+')
            else
              Regexp.escape(string)
            end
          string = string.gsub(/\s+/, '\s+')
          regexp_str = "^"
          regexp_str << '\s*' if ignore_leading
          regexp_str << escaped
          regexp_str << '\s*' if ignore_trailing
          regexp_str << "$"
          Regexp.new(regexp_str)
        end

      end
    end
  end
end
