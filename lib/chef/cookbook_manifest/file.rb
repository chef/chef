# Copyright:: Copyright 2017, Chef Software Inc.
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

class Chef
  class CookbookManifest
    class File

      attr_accessor :part, :path, :specificity, :full_path, :lazy, :url, :filename, :name

      def initialize(name: nil, filename: nil, part: nil, path: nil, full_path: nil, specificity: "default", checksum: nil, lazy: false, url: nil)
        @name = name
        @part = part
        @full_path = full_path
        @path = path
        @specificity = specificity
        @checksum = checksum
        @lazy = lazy
        @url = url
        @filename = filename
      end

      def [](key)
        if respond_to?(key.to_sym)
          send(key.to_sym)
        else
          nil
        end
      end

      def lazy?
        @lazy
      end

      def checksum
        if lazy?
          nil
        else
          @checksum ||= Chef::CookbookVersion.checksum_cookbook_file(full_path)
        end
      end

      def to_hash
        Mash.new({ name: name, path: path, specificity: specificity, checksum: checksum, url: url })
      end

      def self.from_hash(hash)
        part, name = hash[:name].split("/")
        if name.nil?
          name = part
          part = "root_files"
        end
        new(name: hash[:name], filename: name, part: part, path: hash[:path], specificity: hash[:specificity], checksum: hash[:checksum], url: hash[:url] || nil)
      end

      def self.from_full_path(full_path, root_paths)
        Array(root_paths).each do |root|
          pathname = Chef::Util::PathHelper.relative_path_from(root, full_path)

          parts = pathname.each_filename.take(2)
          # Check if path is actually under root_path
          next if parts[0] == ".."

          name = pathname.basename.to_s

          # if we have a root_file, such as metadata.rb, the first part will be "."
          return new(name: name, filename: name, part: "root_files", path: pathname.to_s, full_path: full_path, specificity: "default") if parts.length == 1

          segment = parts[0]
          cname = "#{parts[0]}/#{name}"

          if segment == "templates" || segment == "files"
            # Check if pathname looks like files/foo or templates/foo (unscoped)
            if pathname.each_filename.to_a.length == 2
              # Use root_default in case the same path exists at root_default and default
              return new(name: cname, filename: name, part: segment, path: pathname.to_s, full_path: full_path, specificity: "root_default")
            else
              return new(name: cname, filename: name, part: segment, path: pathname.to_s, full_path: full_path, specificity: parts[1])
            end
          else
            return new(name: cname, filename: name, part: segment, path: pathname.to_s, full_path: full_path, specificity: "default")
          end
        end
        Chef::Log.error("Cookbook file #{full_path} not under cookbook root paths #{root_paths.inspect}.")
        raise "Cookbook file #{full_path} not under cookbook root paths #{root_paths.inspect}."
      end

    end
  end
end
