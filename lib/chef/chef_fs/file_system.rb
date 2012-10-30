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

require 'chef/chef_fs/path_utils'

class Chef
  module ChefFS
    module FileSystem
      # Yields a list of all things under (and including) this entry that match the
      # given pattern.
      #
      # ==== Attributes
      #
      # * +entry+ - Entry to start listing under
      # * +pattern+ - Chef::ChefFS::FilePattern to match children under
      #
      def self.list(entry, pattern, &block)
        # Include self in results if it matches
        if pattern.match?(entry.path)
          block.call(entry)
        end

        if entry.dir? && pattern.could_match_children?(entry.path)
          # If it's possible that our children could match, descend in and add matches.
          exact_child_name = pattern.exact_child_name_under(entry.path)

          # If we've got an exact name, don't bother listing children; just grab the
          # child with the given name.
          if exact_child_name
            exact_child = entry.child(exact_child_name)
            if exact_child
              list(exact_child, pattern, &block)
            end

          # Otherwise, go through all children and find any matches
          else
            entry.children.each do |child|
              list(child, pattern, &block)
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
        return resolve_path(entry.root, path) if path[0,1] == "/" && entry.root != entry
        if path[0,1] == "/"
          path = path[1,path.length-1]
        end

        result = entry
        Chef::ChefFS::PathUtils::split(path).each do |part|
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
      def self.copy_to(pattern, src_root, dest_root, recurse_depth, options)
        found_result = false
        list_pairs(pattern, src_root, dest_root) do |src, dest|
          found_result = true
          new_dest_parent = get_or_create_parent(dest, options)
          copy_entries(src, dest, new_dest_parent, recurse_depth, options)
        end
        if !found_result && pattern.exact_path
          puts "#{pattern}: No such file or directory on remote or local"
        end
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
      #     Chef::ChefFS::FileSystem.list_pairs(FilePattern.new('**x.txt', a_root, b_root)) do |a, b|
      #       ...
      #     end
      #
      def self.list_pairs(pattern, a_root, b_root)
        # Make sure everything on the server is also on the filesystem, and diff
        found_paths = Set.new
        Chef::ChefFS::FileSystem.list(a_root, pattern) do |a|
          found_paths << a.path
          b = Chef::ChefFS::FileSystem.resolve_path(b_root, a.path)
          yield [ a, b ]
        end

        # Check the outer regex pattern to see if it matches anything on the
        # filesystem that isn't on the server
        Chef::ChefFS::FileSystem.list(b_root, pattern) do |b|
          if !found_paths.include?(b.path)
            a = Chef::ChefFS::FileSystem.resolve_path(a_root, b.path)
            yield [ a, b ]
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
          a_children_names << a_child.name
          result << [ a_child, b.child(a_child.name) ]
        end

        # Check b for children that aren't in a
        b.children.each do |b_child|
          if !a_children_names.include?(b_child.name)
            result << [ a.child(b_child.name), b_child ]
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

      private

      # Copy two entries (could be files or dirs)
      def self.copy_entries(src_entry, dest_entry, new_dest_parent, recurse_depth, options)
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

        if !src_entry.exists?
          if options[:purge]
            # If we would not have uploaded it, we will not purge it.
            if src_entry.parent.can_have_child?(dest_entry.name, dest_entry.dir?)
              if options[:dry_run]
                puts "Would delete #{dest_entry.path_for_printing}"
              else
                dest_entry.delete(true)
                puts "Deleted extra entry #{dest_entry.path_for_printing} (purge is on)"
              end
            else
              Chef::Log.info("Not deleting extra entry #{dest_entry.path_for_printing} (purge is off)")
            end
          end

        elsif !dest_entry.exists?
          if new_dest_parent.can_have_child?(src_entry.name, src_entry.dir?)
            # If the entry can do a copy directly from filesystem, do that.
            if new_dest_parent.respond_to?(:create_child_from)
              if options[:dry_run]
                puts "Would create #{dest_entry.path_for_printing}"
              else
                new_dest_parent.create_child_from(src_entry)
                puts "Created #{dest_entry.path_for_printing}"
              end
              return
            end

            if src_entry.dir?
              if options[:dry_run]
                puts "Would create #{dest_entry.path_for_printing}"
                new_dest_dir = new_dest_parent.child(src_entry.name)
              else
                new_dest_dir = new_dest_parent.create_child(src_entry.name, nil)
                puts "Created #{dest_entry.path_for_printing}/"
              end
              # Directory creation is recursive.
              if recurse_depth != 0
                src_entry.children.each do |src_child|
                  new_dest_child = new_dest_dir.child(src_child.name)
                  copy_entries(src_child, new_dest_child, new_dest_dir, recurse_depth ? recurse_depth - 1 : recurse_depth, options)
                end
              end
            else
              if options[:dry_run]
                puts "Would create #{dest_entry.path_for_printing}"
              else
                new_dest_parent.create_child(src_entry.name, src_entry.read)
                puts "Created #{dest_entry.path_for_printing}"
              end
            end
          end

        else
          # Both exist.

          # If the entry can do a copy directly, do that.
          if dest_entry.respond_to?(:copy_from)
            if options[:force] || compare(src_entry, dest_entry)[0] == false
              if options[:dry_run]
                puts "Would update #{dest_entry.path_for_printing}"
              else
                dest_entry.copy_from(src_entry)
                puts "Updated #{dest_entry.path_for_printing}"
              end
            end
            return
          end

          # If they are different types, log an error.
          if src_entry.dir?
            if dest_entry.dir?
              # If both are directories, recurse into their children
              if recurse_depth != 0
                child_pairs(src_entry, dest_entry).each do |src_child, dest_child|
                  copy_entries(src_child, dest_child, dest_entry, recurse_depth ? recurse_depth - 1 : recurse_depth, options)
                end
              end
            else
              # If they are different types.
              Chef::Log.error("File #{dest_entry.path_for_printing} is a directory while file #{dest_entry.path_for_printing} is a regular file\n")
              return
            end
          else
            if dest_entry.dir?
              Chef::Log.error("File #{dest_entry.path_for_printing} is a directory while file #{dest_entry.path_for_printing} is a regular file\n")
              return
            else

              # Both are files!  Copy them unless we're sure they are the same.
              if options[:force]
                should_copy = true
                src_value = nil
              else
                are_same, src_value, dest_value = compare(src_entry, dest_entry)
                should_copy = !are_same
              end
              if should_copy
                if options[:dry_run]
                  puts "Would update #{dest_entry.path_for_printing}"
                else
                  src_value = src_entry.read if src_value.nil?
                  dest_entry.write(src_value)
                  puts "Updated #{dest_entry.path_for_printing}"
                end
              end
            end
          end
        end
      end

      def self.get_or_create_parent(entry, options)
        parent = entry.parent
        if parent && !parent.exists?
          parent_parent = get_or_create_parent(entry.parent, options)
          if options[:dry_run]
            puts "Would create #{parent.path_for_printing}"
          else
            parent = parent_parent.create_child(parent.name, true)
            puts "Created #{parent.path_for_printing}"
          end
        end
        return parent
      end

    end
  end
end
