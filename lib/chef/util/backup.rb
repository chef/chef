#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/util/path_helper"

class Chef
  class Util
    class Backup
      attr_reader :new_resource
      attr_accessor :path

      def initialize(new_resource, path = nil)
        @new_resource = new_resource
        @path = path.nil? ? new_resource.path : path
      end

      def backup!
        if @new_resource.backup != false && @new_resource.backup > 0 && ::File.exist?(path)
          do_backup
          # Clean up after the number of backups
          slice_number = @new_resource.backup
          backup_files = sorted_backup_files
          if backup_files.length >= @new_resource.backup
            remainder = backup_files.slice(slice_number..-1)
            remainder.each do |backup_to_delete|
              delete_backup(backup_to_delete)
            end
          end
        end
      end

      private

      def backup_filename
        @backup_filename ||= begin
          time = Time.now
          nanoseconds = sprintf("%6f", time.to_f).split(".")[1]
          savetime = time.strftime("%Y%m%d%H%M%S.#{nanoseconds}")
          backup_filename = "#{path}.chef-#{savetime}"
          backup_filename = backup_filename.sub(/^([A-Za-z]:)/, "") #strip drive letter on Windows
        end
      end

      def prefix
        # if :file_backup_path is nil, we fallback to the old behavior of
        # keeping the backup in the same directory. We also need to to_s it
        # so we don't get a type error around implicit to_str conversions.
        @prefix ||= Chef::Config[:file_backup_path].to_s
      end

      def backup_path
        @backup_path ||= ::File.join(prefix, backup_filename)
      end

      def do_backup
        FileUtils.mkdir_p(::File.dirname(backup_path)) if Chef::Config[:file_backup_path]
        FileUtils.cp(path, backup_path, :preserve => true)
        Chef::Log.info("#{@new_resource} backed up to #{backup_path}")
      end

      def delete_backup(backup_file)
        FileUtils.rm(backup_file)
        Chef::Log.info("#{@new_resource} removed backup at #{backup_file}")
      end

      def unsorted_backup_files
        # If you replace this with Dir[], you will probably break Windows.
        fn = Regexp.escape(::File.basename(path))
        Dir.entries(::File.dirname(backup_path)).select do |f|
          !!(f =~ /\A#{fn}.chef-[0-9.]*\B/)
        end.map { |f| ::File.join(::File.dirname(backup_path), f) }
      end

      def sorted_backup_files
        unsorted_backup_files.sort { |a, b| b <=> a }
      end
    end
  end
end
