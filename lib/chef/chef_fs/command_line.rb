#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system"
require "chef/chef_fs/file_system/exceptions"
require "chef/util/diff"

class Chef
  module ChefFS
    module CommandLine

      def self.diff_print(pattern, a_root, b_root, recurse_depth, output_mode, format_path = nil, diff_filter = nil, ui = nil)
        if format_path.nil?
          format_path = proc { |entry| entry.path_for_printing }
        end

        get_content = (output_mode != :name_only && output_mode != :name_status)
        found_match = false
        diff(pattern, a_root, b_root, recurse_depth, get_content).each do |type, old_entry, new_entry, old_value, new_value, error|
          found_match = true unless type == :both_nonexistent
          old_path = format_path.call(old_entry)
          new_path = format_path.call(new_entry)

          case type
          when :common_subdirectories
            if output_mode != :name_only && output_mode != :name_status
              yield "Common subdirectories: #{new_path}\n"
            end

          when :directory_to_file
            next if diff_filter && diff_filter !~ /T/
            if output_mode == :name_only
              yield "#{new_path}\n"
            elsif output_mode == :name_status
              yield "T\t#{new_path}\n"
            else
              yield "File #{old_path} is a directory while file #{new_path} is a regular file\n"
            end

          when :file_to_directory
            next if diff_filter && diff_filter !~ /T/
            if output_mode == :name_only
              yield "#{new_path}\n"
            elsif output_mode == :name_status
              yield "T\t#{new_path}\n"
            else
              yield "File #{old_path} is a regular file while file #{new_path} is a directory\n"
            end

          when :deleted
            # This is kind of a kludge - because the "new" entry isn't there, we can't predict
            # it's true file name, because we've not got enough information. So because we know
            # the two entries really ought to have the same extension, we'll just grab the old one
            # and use it. (This doesn't affect cookbook files, since they'll always have extensions)
            if File.extname(old_path) != File.extname(new_path)
              new_path += File.extname(old_path)
            end
            next if diff_filter && diff_filter !~ /D/
            if output_mode == :name_only
              yield "#{new_path}\n"
            elsif output_mode == :name_status
              yield "D\t#{new_path}\n"
            elsif old_value
              result = "diff --knife #{old_path} #{new_path}\n"
              result << "deleted file\n"
              result << diff_text(old_path, "/dev/null", old_value, "")
              yield result
            else
              yield "Only in #{format_path.call(old_entry.parent)}: #{old_entry.name}\n"
            end

          when :added
            next if diff_filter && diff_filter !~ /A/
            if output_mode == :name_only
              yield "#{new_path}\n"
            elsif output_mode == :name_status
              yield "A\t#{new_path}\n"
            elsif new_value
              result = "diff --knife #{old_path} #{new_path}\n"
              result << "new file\n"
              result << diff_text("/dev/null", new_path, "", new_value)
              yield result
            else
              yield "Only in #{format_path.call(new_entry.parent)}: #{new_entry.name}\n"
            end

          when :modified
            next if diff_filter && diff_filter !~ /M/
            if output_mode == :name_only
              yield "#{new_path}\n"
            elsif output_mode == :name_status
              yield "M\t#{new_path}\n"
            else
              result = "diff --knife #{old_path} #{new_path}\n"
              result << diff_text(old_path, new_path, old_value, new_value)
              yield result
            end

          when :both_nonexistent
          when :added_cannot_upload
          when :deleted_cannot_download
          when :same
            # Skip these silently
          when :error
            if error.is_a?(Chef::ChefFS::FileSystem::OperationFailedError)
              ui.error "#{format_path.call(error.entry)} failed to #{error.operation}: #{error.message}" if ui
              error = true
            elsif error.is_a?(Chef::ChefFS::FileSystem::OperationNotAllowedError)
              ui.error "#{format_path.call(error.entry)} #{error.reason}." if ui
            else
              raise error
            end
          end
        end
        if !found_match
          ui.error "#{pattern}: No such file or directory on remote or local" if ui
          error = true
        end
        error
      end

      def self.diff(pattern, old_root, new_root, recurse_depth, get_content)
        Chef::ChefFS::Parallelizer.parallelize(Chef::ChefFS::FileSystem.list_pairs(pattern, old_root, new_root)) do |old_entry, new_entry|
          diff_entries(old_entry, new_entry, recurse_depth, get_content)
        end.flatten(1)
      end

      # Diff two known entries (could be files or dirs)
      def self.diff_entries(old_entry, new_entry, recurse_depth, get_content)
        # If both are directories
        if old_entry.dir?
          if new_entry.dir?
            if recurse_depth == 0
              return [ [ :common_subdirectories, old_entry, new_entry ] ]
            else
              return Chef::ChefFS::Parallelizer.parallelize(Chef::ChefFS::FileSystem.child_pairs(old_entry, new_entry)) do |old_child, new_child|
                Chef::ChefFS::CommandLine.diff_entries(old_child, new_child, recurse_depth ? recurse_depth - 1 : nil, get_content)
              end.flatten(1)
            end

          # If old is a directory and new is a file
          elsif new_entry.exists?
            return [ [ :directory_to_file, old_entry, new_entry ] ]

          # If old is a directory and new does not exist
          elsif new_entry.parent.can_have_child?(old_entry.name, old_entry.dir?)
            return [ [ :deleted, old_entry, new_entry ] ]

          # If the new entry does not and *cannot* exist, report that.
          else
            return [ [ :new_cannot_upload, old_entry, new_entry ] ]
          end

        # If new is a directory and old is a file
        elsif new_entry.dir?
          if old_entry.exists?
            return [ [ :file_to_directory, old_entry, new_entry ] ]

          # If new is a directory and old does not exist
          elsif old_entry.parent.can_have_child?(new_entry.name, new_entry.dir?)
            return [ [ :added, old_entry, new_entry ] ]

          # If the new entry does not and *cannot* exist, report that.
          else
            return [ [ :old_cannot_upload, old_entry, new_entry ] ]
          end

        # Neither is a directory, so they are diffable with file diff
        else
          are_same, old_value, new_value = Chef::ChefFS::FileSystem.compare(old_entry, new_entry)
          if are_same
            if old_value == :none
              return [ [ :both_nonexistent, old_entry, new_entry ] ]
            else
              return [ [ :same, old_entry, new_entry ] ]
            end
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
              return [ [ :old_cannot_upload, old_entry, new_entry ] ]
            end
            if !new_exists && !new_entry.parent.can_have_child?(old_entry.name, old_entry.dir?)
              return [ [ :new_cannot_upload, old_entry, new_entry ] ]
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

            if old_value == :none || (old_value.nil? && !old_entry.exists?)
              return [ [ :added, old_entry, new_entry, old_value, new_value ] ]
            elsif new_value == :none
              return [ [ :deleted, old_entry, new_entry, old_value, new_value ] ]
            else
              return [ [ :modified, old_entry, new_entry, old_value, new_value ] ]
            end
          end
        end
      rescue Chef::ChefFS::FileSystem::FileSystemError => e
        return [ [ :error, old_entry, new_entry, nil, nil, e ] ]
      end

      class << self
        private

        def sort_keys(json_object)
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

        def canonicalize_json(json_text)
          parsed_json = Chef::JSONCompat.parse(json_text)
          sorted_json = sort_keys(parsed_json)
          Chef::JSONCompat.to_json_pretty(sorted_json)
        end

        def diff_text(old_path, new_path, old_value, new_value)
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

              result = Chef::Util::Diff.new.udiff(old_tempfile.path, new_tempfile.path)
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
end
