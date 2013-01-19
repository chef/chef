#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs/file_system'

class Chef
  module ChefFS
    module CommandLine

      def self.diff_print(pattern, a_root, b_root, recurse_depth, output_mode, format_path = nil)
        if format_path.nil?
          format_path = proc { |entry| entry.path_for_printing }
        end

        get_content = (output_mode != :name_only && output_mode != :name_status)
        diff(pattern, a_root, b_root, recurse_depth, get_content) do |type, old_entry, new_entry, old_value, new_value|
          old_path = format_path.call(old_entry)
          new_path = format_path.call(new_entry)

          if get_content && old_value && new_value
            result = ''
            result << "diff --knife #{old_path} #{new_path}\n"
            if old_value == :none
              result << "new file\n"
              old_path = "/dev/null"
              old_value = ''
            end
            if new_value == :none
              result << "deleted file\n"
              new_path = "/dev/null"
              new_value = ''
            end
            result << diff_text(old_path, new_path, old_value, new_value)
            yield result
          else
            case type
            when :common_subdirectories
              if output_mode != :name_only && output_mode != :name_status
                yield "Common subdirectories: #{new_path}\n"
              end
            when :directory_to_file
              if output_mode == :name_only
                yield "#{new_path}\n"
              elsif output_mode == :name_status
                yield "T\t#{new_path}\n"
              else
                yield "File #{old_path} is a directory while file #{new_path} is a regular file\n"
              end
            when :file_to_directory
              if output_mode == :name_only
                yield "#{new_path}\n"
              elsif output_mode == :name_status
                yield "T\t#{new_path}\n"
              else
                yield "File #{old_path} is a regular file while file #{new_path} is a directory\n"
              end
            when :deleted
              if output_mode == :name_only
                yield "#{new_path}\n"
              elsif output_mode == :name_status
                yield "D\t#{new_path}\n"
              else
                yield "Only in #{format_path.call(old_entry.parent)}: #{old_entry.name}\n"
              end
            when :added
              if output_mode == :name_only
                yield "#{new_path}\n"
              elsif output_mode == :name_status
                yield "A\t#{new_path}\n"
              else
                yield "Only in #{format_path.call(new_entry.parent)}: #{new_entry.name}\n"
              end
            when :modified
              if output_mode == :name_only
                yield "#{new_path}\n"
              elsif output_mode == :name_status
                yield "M\t#{new_path}\n"
              end
            end
          end
        end
      end

      def self.diff(pattern, a_root, b_root, recurse_depth, get_content)
        found_result = false
        Chef::ChefFS::FileSystem.list_pairs(pattern, a_root, b_root) do |a, b|
          existed = diff_entries(a, b, recurse_depth, get_content) do |diff|
            yield diff
          end
          found_result = true if existed
        end
        if !found_result && pattern.exact_path
          yield "#{pattern}: No such file or directory on remote or local"
        end
      end

      # Diff two known entries (could be files or dirs)
      def self.diff_entries(old_entry, new_entry, recurse_depth, get_content)
        # If both are directories
        if old_entry.dir?
          if new_entry.dir?
            if recurse_depth == 0
              yield [ :common_subdirectories, old_entry, new_entry ]
            else
              Chef::ChefFS::FileSystem.child_pairs(old_entry, new_entry).each do |old_child,new_child|
                diff_entries(old_child, new_child,
                             recurse_depth ? recurse_depth - 1 : nil, get_content) do |diff|
                  yield diff
                end
              end
            end

        # If old is a directory and new is a file
          elsif new_entry.exists?
            yield [ :directory_to_file, old_entry, new_entry ]

        # If old is a directory and new does not exist
          elsif new_entry.parent.can_have_child?(old_entry.name, old_entry.dir?)
            yield [ :deleted, old_entry, new_entry ]
          end

        # If new is a directory and old is a file
        elsif new_entry.dir?
          if old_entry.exists?
            yield [ :file_to_directory, old_entry, new_entry ]

        # If new is a directory and old does not exist
          elsif old_entry.parent.can_have_child?(new_entry.name, new_entry.dir?)
            yield [ :added, old_entry, new_entry ]
          end

        # Neither is a directory, so they are diffable with file diff
        else
          are_same, old_value, new_value = Chef::ChefFS::FileSystem.compare(old_entry, new_entry)
          if are_same
            return old_value != :none
          else
            if old_value == :none
              old_exists = false
            elsif old_value.nil?
              old_exists = old_entry.exists?
            else
              old_exists = true
            end

            if new_value == :none
              new_exists = false
            elsif new_value.nil?
              new_exists = new_entry.exists?
            else
              new_exists = true
            end

            # If one of the files doesn't exist, we only want to print the diff if the
            # other file *could be uploaded/downloaded*.
            if !old_exists && !old_entry.parent.can_have_child?(new_entry.name, new_entry.dir?)
              return true
            end
            if !new_exists && !new_entry.parent.can_have_child?(old_entry.name, old_entry.dir?)
              return true
            end

            if get_content
              # If we haven't read the values yet, get them now so that they can be diffed
              begin
                old_value = old_entry.read if old_value.nil?
              rescue Chef::ChefFS::FileSystem::NotFoundError
                old_value = :none
              end
              begin
                new_value = new_entry.read if new_value.nil?
              rescue Chef::ChefFS::FileSystem::NotFoundError
                new_value = :none
              end
            end

            if old_value == :none || (old_value == nil && !old_entry.exists?)
              yield [ :added, old_entry, new_entry, old_value, new_value ]
            elsif new_value == :none
              yield [ :deleted, old_entry, new_entry, old_value, new_value ]
            else
              yield [ :modified, old_entry, new_entry, old_value, new_value ]
            end
          end
        end
        return true
      end

      private

      def self.sort_keys(json_object)
        if json_object.is_a?(Array)
          json_object.map { |o| sort_keys(o) }
        elsif json_object.is_a?(Hash)
          new_hash = {}
          json_object.keys.sort.each { |key| new_hash[key] = sort_keys(json_object[key]) }
          new_hash
        else
          json_object
        end
      end

      def self.canonicalize_json(json_text)
        parsed_json = JSON.parse(json_text, :create_additions => false)
        sorted_json = sort_keys(parsed_json)
        JSON.pretty_generate(sorted_json)
      end

      def self.diff_text(old_path, new_path, old_value, new_value)
        # Reformat JSON for a nicer diff.
        if old_path =~ /\.json$/
          begin
            reformatted_old_value = canonicalize_json(old_value)
            reformatted_new_value = canonicalize_json(new_value)
            old_value = reformatted_old_value
            new_value = reformatted_new_value
          rescue
            # If JSON parsing fails, we just won't change any values and fall back
            # to normal diff.
          end
        end

        # Copy to tempfiles before diffing
        # TODO don't copy things that are already in files!  Or find an in-memory diff algorithm
        begin
          new_tempfile = Tempfile.new("new")
          new_tempfile.write(new_value)
          new_tempfile.close

          begin
            old_tempfile = Tempfile.new("old")
            old_tempfile.write(old_value)
            old_tempfile.close

            result = `diff -u #{old_tempfile.path} #{new_tempfile.path}`
            result = result.gsub(/^--- #{old_tempfile.path}/, "--- #{old_path}")
            result = result.gsub(/^\+\+\+ #{new_tempfile.path}/, "+++ #{new_path}")
            result
          ensure
            old_tempfile.close!
          end
        ensure
          new_tempfile.close!
        end
      end
    end
  end
end
