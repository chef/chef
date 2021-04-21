#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "path_utils"
require_relative "file_system/exceptions"
require "chef-utils/parallel_map" unless defined?(ChefUtils::ParallelMap)

using ChefUtils::ParallelMap

class Chef
  module ChefFS
    module FileSystem
      # Returns a list of all things under (and including) this entry that match the
      # given pattern.
      #
      # ==== Attributes
      #
      # * +root+ - Entry to start listing under
      # * +pattern+ - Chef::ChefFS::FilePattern to match children under
      #
      def self.list(root, pattern)
        Lister.new(root, pattern)
      end

      class Lister
        include Enumerable

        def initialize(root, pattern)
          @root = root
          @pattern = pattern
        end

        attr_reader :root
        attr_reader :pattern

        def each(&block)
          list_from(root, &block)
        end

        def list_from(entry, &block)
          # Include self in results if it matches
          if pattern.match?(entry.display_path)
            yield(entry)
          end

          if pattern.could_match_children?(entry.display_path)
            # If it's possible that our children could match, descend in and add matches.
            exact_child_name = pattern.exact_child_name_under(entry.display_path)

            # If we've got an exact name, don't bother listing children; just grab the
            # child with the given name.
            if exact_child_name
              exact_child = entry.child(exact_child_name)
              if exact_child
                list_from(exact_child, &block)
              end

              # Otherwise, go through all children and find any matches
            elsif entry.dir?
              results = entry.children.parallel_map { |child| Chef::ChefFS::FileSystem.list(child, pattern) }
              results.flat_each(&block)
            end
          end
        end
      end

      # Resolve the given path against the entry, returning
      # the entry at the end of the path.
      #
      # ==== Attributes
      #
      # * +entry+ - the entry to start looking under.  Relative
      #   paths will be resolved from here.
      # * +path+ - the path to resolve.  If it starts with +/+,
      #   the path will be resolved starting from +entry.root+.
      #
      # ==== Examples
      #
      #     Chef::ChefFS::FileSystem.resolve_path(root_path, 'cookbooks/java/recipes/default.rb')
      #
      def self.resolve_path(entry, path)
        return entry if path.length == 0
        return resolve_path(entry.root, path) if path[0, 1] == "/" && entry.root != entry

        if path[0, 1] == "/"
          path = path[1, path.length - 1]
        end

        result = entry
        Chef::ChefFS::PathUtils.split(path).each do |part|
          result = result.child(part)
        end
        result
      end

      # Copy everything matching the given pattern from src to dest.
      #
      # After this method completes, everything in dest matching the
      # given pattern will look identical to src.
      #
      # ==== Attributes
      #
      # * +pattern+ - Chef::ChefFS::FilePattern to match children under
      # * +src_root+ - the root from which things will be copied
      # * +dest_root+ - the root to which things will be copied
      # * +recurse_depth+ - the maximum depth to copy things. +nil+
      #   means infinite depth.  0 means no recursion.
      # * +options+ - hash of options:
      #   - +purge+ - if +true+, items in +dest+ that are not in +src+
      #   will be deleted from +dest+.  If +false+, these items will
      #   be left alone.
      #   - +force+ - if +true+, matching files are always copied from
      #     +src+ to +dest+.  If +false+, they will only be copied if
      #     actually different (which will take time to determine).
      #   - +dry_run+ - if +true+, action will not actually be taken;
      #     things will be printed out instead.
      #
      # ==== Examples
      #
      #     Chef::ChefFS::FileSystem.copy_to(FilePattern.new('/cookbooks'),
      #       chef_fs, local_fs, nil, true) do |message|
      #       puts message
      #     end
      #
      def self.copy_to(pattern, src_root, dest_root, recurse_depth, options, ui = nil, format_path = nil)
        found_result = false
        error = false
        list_pairs(pattern, src_root, dest_root).parallel_each do |src, dest|
          found_result = true
          new_dest_parent = get_or_create_parent(dest, options, ui, format_path)
          child_error = copy_entries(src, dest, new_dest_parent, recurse_depth, options, ui, format_path)
          error ||= child_error
        end
        if !found_result && pattern.exact_path
          ui.error "#{pattern}: No such file or directory on remote or local" if ui
          error = true
        end
        error
      end

      # Yield entries for children that are in either +a_root+ or +b_root+, with
      # matching pairs matched up.
      #
      # ==== Yields
      #
      # Yields matching entries in pairs:
      #
      #    [ a_entry, b_entry ]
      #
      # ==== Example
      #
      #     Chef::ChefFS::FileSystem.list_pairs(FilePattern.new('**x.txt', a_root, b_root)).each do |a, b|
      #       ...
      #     end
      #
      def self.list_pairs(pattern, a_root, b_root)
        PairLister.new(pattern, a_root, b_root)
      end

      class PairLister
        include Enumerable

        def initialize(pattern, a_root, b_root)
          @pattern = pattern
          @a_root = a_root
          @b_root = b_root
        end

        attr_reader :pattern
        attr_reader :a_root
        attr_reader :b_root

        def each
          # Make sure everything on the server is also on the filesystem, and diff
          found_paths = Set.new
          Chef::ChefFS::FileSystem.list(a_root, pattern).each do |a|
            found_paths << a.display_path
            b = Chef::ChefFS::FileSystem.resolve_path(b_root, a.display_path)
            yield [ a, b ]
          end

          # Check the outer regex pattern to see if it matches anything on the
          # filesystem that isn't on the server
          Chef::ChefFS::FileSystem.list(b_root, pattern).each do |b|
            unless found_paths.include?(b.display_path)
              a = Chef::ChefFS::FileSystem.resolve_path(a_root, b.display_path)
              yield [ a, b ]
            end
          end
        end
      end

      # Get entries for children of either a or b, with matching pairs matched up.
      #
      # ==== Returns
      #
      # An array of child pairs.
      #
      #     [ [ a_child, b_child ], ... ]
      #
      # If a child is only in a or only in b, the other child entry will be
      # retrieved by name (and will most likely be a "nonexistent child").
      #
      # ==== Example
      #
      #     Chef::ChefFS::FileSystem.child_pairs(a, b).length
      #
      def self.child_pairs(a, b)
        # If both are directories, recurse into them and diff the children instead of returning ourselves.
        result = []
        a_children_names = Set.new
        a.children.each do |a_child|
          a_children_names << a_child.bare_name
          result << [ a_child, b.child(a_child.bare_name) ]
        end

        # Check b for children that aren't in a
        b.children.each do |b_child|
          unless a_children_names.include?(b_child.bare_name)
            result << [ a.child(b_child.bare_name), b_child ]
          end
        end
        result
      end

      def self.compare(a, b)
        are_same, a_value, b_value = a.compare_to(b)
        if are_same.nil?
          are_same, b_value, a_value = b.compare_to(a)
        end
        if are_same.nil?
          # TODO these reads can be parallelized
          begin
            a_value = a.read if a_value.nil?
          rescue Chef::ChefFS::FileSystem::NotFoundError
            a_value = :none
          end
          begin
            b_value = b.read if b_value.nil?
          rescue Chef::ChefFS::FileSystem::NotFoundError
            b_value = :none
          end
          are_same = (a_value == b_value)
        end
        [ are_same, a_value, b_value ]
      end

      class << self
        private

        # Copy two entries (could be files or dirs)
        def copy_entries(src_entry, dest_entry, new_dest_parent, recurse_depth, options, ui, format_path)
          # A NOTE about this algorithm:
          # There are cases where this algorithm does too many network requests.
          # knife upload with a specific filename will first check if the file
          # exists (a "dir" in the parent) before deciding whether to POST or
          # PUT it.  If we just tried PUT (or POST) and then tried the other if
          # the conflict failed, we wouldn't need to check existence.
          # On the other hand, we may already have DONE the request, in which
          # case we shouldn't waste time trying PUT if we know the file doesn't
          # exist.
          # Will need to decide how that works with checksums, though.
          error = false
          begin
            dest_path = format_path.call(dest_entry) if ui
            src_path = format_path.call(src_entry) if ui
            if !src_entry.exists?
              if options[:purge]
                # If we would not have uploaded it, we will not purge it.
                if src_entry.parent.can_have_child?(dest_entry.name, dest_entry.dir?)
                  if options[:dry_run]
                    ui.output "Would delete #{dest_path}" if ui
                  else
                    begin
                      dest_entry.delete(true)
                      ui.output "Deleted extra entry #{dest_path} (purge is on)" if ui
                    rescue Chef::ChefFS::FileSystem::NotFoundError
                      ui.output "Entry #{dest_path} does not exist. Nothing to do. (purge is on)" if ui
                    end
                  end
                else
                  ui.output("Not deleting extra entry #{dest_path} (purge is off)") if ui
                end
              end

            elsif !dest_entry.exists?
              if new_dest_parent.can_have_child?(src_entry.name, src_entry.dir?)
                # If the entry can do a copy directly from filesystem, do that.
                if new_dest_parent.respond_to?(:create_child_from)
                  if options[:dry_run]
                    ui.output "Would create #{dest_path}" if ui
                  else
                    new_dest_parent.create_child_from(src_entry)
                    ui.output "Created #{dest_path}" if ui
                  end
                  return
                end

                if src_entry.dir?
                  if options[:dry_run]
                    ui.output "Would create #{dest_path}" if ui
                    new_dest_dir = new_dest_parent.child(src_entry.name)
                  else
                    new_dest_dir = new_dest_parent.create_child(src_entry.name, nil)
                    ui.output "Created #{dest_path}" if ui
                  end
                  # Directory creation is recursive.
                  if recurse_depth != 0
                    src_entry.children.parallel_each do |src_child|
                      new_dest_child = new_dest_dir.child(src_child.name)
                      child_error = copy_entries(src_child, new_dest_child, new_dest_dir, recurse_depth ? recurse_depth - 1 : recurse_depth, options, ui, format_path)
                      error ||= child_error
                    end
                  end
                else
                  if options[:dry_run]
                    ui.output "Would create #{dest_path}" if ui
                  else
                    child = new_dest_parent.create_child(src_entry.name, src_entry.read)
                    ui.output "Created #{format_path.call(child)}" if ui
                  end
                end
              end

            else
              # Both exist.

              # If the entry can do a copy directly, do that.
              if dest_entry.respond_to?(:copy_from)
                if options[:force] || compare(src_entry, dest_entry)[0] == false
                  if options[:dry_run]
                    ui.output "Would update #{dest_path}" if ui
                  else
                    dest_entry.copy_from(src_entry, options)
                    ui.output "Updated #{dest_path}" if ui
                  end
                end
                return
              end

              # If they are different types, log an error.
              if src_entry.dir?
                if dest_entry.dir?
                  # If both are directories, recurse into their children
                  if recurse_depth != 0
                    child_pairs(src_entry, dest_entry).parallel_each do |src_child, dest_child|
                      child_error = copy_entries(src_child, dest_child, dest_entry, recurse_depth ? recurse_depth - 1 : recurse_depth, options, ui, format_path)
                      error ||= child_error
                    end
                  end
                else
                  # If they are different types.
                  ui.error("File #{src_path} is a directory while file #{dest_path} is a regular file\n") if ui
                  return
                end
              else
                if dest_entry.dir?
                  ui.error("File #{src_path} is a regular file while file #{dest_path} is a directory\n") if ui
                  return
                else

                  # Both are files!  Copy them unless we're sure they are the same.'
                  if options[:diff] == false
                    should_copy = false
                  elsif options[:force]
                    should_copy = true
                    src_value = nil
                  else
                    are_same, src_value, _dest_value = compare(src_entry, dest_entry)
                    should_copy = !are_same
                  end
                  if should_copy
                    if options[:dry_run]
                      ui.output "Would update #{dest_path}" if ui
                    else
                      src_value = src_entry.read if src_value.nil?
                      dest_entry.write(src_value)
                      ui.output "Updated #{dest_path}" if ui
                    end
                  end
                end
              end
            end
          rescue RubyFileError => e
            ui.warn "#{format_path.call(e.entry)} #{e.reason}." if ui
          rescue DefaultEnvironmentCannotBeModifiedError => e
            ui.warn "#{format_path.call(e.entry)} #{e.reason}." if ui
          rescue OperationFailedError => e
            ui.error "#{format_path.call(e.entry)} failed to #{e.operation}: #{e.message}" if ui
            error = true
          rescue OperationNotAllowedError => e
            ui.error "#{format_path.call(e.entry)} #{e.reason}." if ui
            error = true
          end
          error
        end

        def get_or_create_parent(entry, options, ui, format_path)
          parent = entry.parent
          if parent && !parent.exists?
            parent_path = format_path.call(parent) if ui
            parent_parent = get_or_create_parent(parent, options, ui, format_path)
            if options[:dry_run]
              ui.output "Would create #{parent_path}" if ui
            else
              parent = parent_parent.create_child(parent.name, nil)
              ui.output "Created #{parent_path}" if ui
            end
          end
          parent
        end

      end
    end
  end
end
