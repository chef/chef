require 'chef/chef_fs/knife'
require 'chef_zero/server'
require 'chef_zero/data_store/memory_store'

# For ChefFSStore
require 'chef/chef_fs/file_pattern'
require 'chef/chef_fs/file_system'
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/chef_fs/file_system/memory_root'
require 'chef_zero/data_store/data_already_exists_error'
require 'chef_zero/data_store/data_not_found_error'

class Chef
  class Knife
    class Zero < Chef::ChefFS::Knife
      banner "knife show [PATTERN1 ... PATTERNn]"

      common_options

      option :remote,
        :long => '--remote',
        :boolean => true,
        :description => "Proxy the remote server instead of the local filesystem"

      def run
        data_store = ChefFSDataStore.new(config[:remote] ? chef_fs : local_fs)
        ChefZero::Server.new(:data_store => data_store, :log_level => Chef::Log.level).start(:publish => true)
      end

      class ChefFSDataStore
        def initialize(chef_fs)
          @chef_fs = chef_fs
          @memory_store = ChefZero::DataStore::MemoryStore.new
        end

        attr_reader :chef_fs

        MEMORY_PATHS = %w(sandboxes file_store)

        def create_dir(path, name, *options)
          if is_memory_store(path)
            @memory_store.create_dir(path, name, *options)
          else
            with_dir(path) do |parent|
              parent.create_child(chef_fs_filename(path + [name]), nil)
            end
          end
        end

        def create(path, name, data, *options)
          if is_memory_store(path)
            @memory_store.create(path, name, data, *options)

          elsif path[0] == 'cookbooks' && path.length == 2
            # Do nothing.  The entry gets created when the cookbook is created.

          else
            if !data.is_a?(String)
              raise "set only works with strings"
            end

            with_dir(path) do |parent|
              parent.create_child(chef_fs_filename(path + [name]), data)
            end
          end
        end

        def get(path, request=nil)
          if is_memory_store(path)
            @memory_store.get(path)

          elsif path[0] == 'file_store' && path[1] == 'repo'
            entry = Chef::ChefFS::FileSystem.resolve_path(chef_fs, path[2..-1].join('/'))
            begin
              entry.read
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
            end

          else
            with_entry(path) do |entry|
              if path[0] == 'cookbooks' && path.length == 3
                # get /cookbooks/NAME/version
                result = entry.chef_object.to_hash
                result.each_pair do |key, value|
                  if value.is_a?(Array)
                    value.each do |file|
                      if file.is_a?(Hash) && file.has_key?('checksum')
                        relative = ['file_store', 'repo', 'cookbooks']
                        if Chef::Config.versioned_cookbooks
                          relative << "#{path[1]}-#{path[2]}"
                        else
                          relative << path[1]
                        end
                        relative = relative + file[:path].split('/')
                        file['url'] = ChefZero::RestBase::build_uri(request.base_uri, relative)
                      end
                    end
                  end
                end
                JSON.pretty_generate(result)

              else
                entry.read
              end
            end
          end
        end

        def set(path, data, *options)
          if is_memory_store(path)
            @memory_store.set(path, data, *options)
          else
            if !data.is_a?(String)
              raise "set only works with strings: #{path} = #{data.inspect}"
            end

            # Write out the files!
            if path[0] == 'cookbooks' && path.length == 3
              write_cookbook(path, data, *options)
            else
              with_dir(path[0..-2]) do |parent|
                parent.create_child(chef_fs_filename(path), data)
              end
            end
          end
        end

        def delete(path)
          if is_memory_store(path)
            @memory_store.delete(path)
          else
            with_entry(path) do |entry|
              if path[0] == 'cookbooks' && path.length >= 3
                entry.delete(true)
              else
                entry.delete
              end
            end
          end
        end

        def delete_dir(path, *options)
          if is_memory_store(path)
            @memory_store.delete_dir(path, *options)
          else
            with_entry(path) do |entry|
              entry.delete(options.include?(:recursive))
            end
          end
        end

        def list(path)
          if is_memory_store(path)
            @memory_store.list(path)

          elsif path[0] == 'cookbooks' && path.length == 1
            with_entry(path) do |entry|
              if Chef::Config.versioned_cookbooks
                # /cookbooks/name-version -> /cookbooks/name
                entry.children.map { |child| split_name_version(child.name)[0] }.uniq
              else
                entry.children.map { |child| child.name }
              end
            end

          elsif path[0] == 'cookbooks' && path.length == 2
            if Chef::Config.versioned_cookbooks
              # list /cookbooks/name = filter /cookbooks/name-version down to name
              entry.children.map { |child| split_name_version(child.name) }.
                             select { |name, version| name == path[1] }.
                             map { |name, version| version }.to_a
            else
              # list /cookbooks/name = <single version>
              version = get_single_cookbook_version(path)
              [version]
            end

          else
            with_entry(path) do |entry|
              entry.children.map { |c| to_leaf_name(c) }.sort
            end
          end
        end

        def exists?(path)
          if is_memory_store(path)
            @memory_store.exists?(path)
          else
            Chef::ChefFS::FileSystem.resolve_path(chef_fs, path_to_chef_fs(path)).exists?
          end
        end

        def exists_dir?(path)
          if is_memory_store(path)
            @memory_store.exists_dir?(path)
          elsif path[0] == 'cookbooks' && path.length == 2
            list([ path[0] ]).include?(path[1])
          else
            Chef::ChefFS::FileSystem.resolve_path(chef_fs, path_to_chef_fs(path)).exists?
          end
        end

        private

        def is_memory_store(path)
          return path[0] == 'sandboxes' || path[0] == 'file_store' && path[1] == 'checksums'
        end

        def write_cookbook(path, data, *options)
          # Create a little Chef::ChefFS memory filesystem with the data
          if Chef::Config.versioned_cookbooks
            cookbook_path = "cookbooks/#{path[1]}-#{path[2]}"
          else
            cookbook_path = "cookbooks/#{path[1]}"
          end
          cookbook_fs = Chef::ChefFS::FileSystem::MemoryRoot.new('uploading')
          cookbook = JSON.parse(data, :create_additions => false)
          cookbook.each_pair do |key, value|
            if value.is_a?(Array)
              value.each do |file|
                if file.is_a?(Hash) && file.has_key?('checksum')
                  file_data = @memory_store.get(['file_store', 'checksums', file['checksum']])
                  cookbook_fs.add_file("#{cookbook_path}/#{file['path']}", file_data)
                end
              end
            end
          end

          # Use the copy/diff algorithm to copy it down so we don't destroy
          # chefignored data.  This is terribly un-thread-safe.
          Chef::ChefFS::FileSystem.copy_to(Chef::ChefFS::FilePattern.new(cookbook_path), cookbook_fs, chef_fs, nil, {:purge => true})
        end

        def split_name_version(entry_name)
          name_version = entry_name.split('-')
          name = name_version[0..-2].join('-')
          version = name_version[-1]
          [name,version]
        end

        def path_to_chef_fs(path)
          _path_to_chef_fs(path).join('/')
        end

        def chef_fs_filename(path)
          _path_to_chef_fs(path)[-1]
        end

        def _path_to_chef_fs(path)
          if path[0] == 'data'
            path = path.dup
            path[0] = 'data_bags'
            if path.length >= 3
              path[2] = "#{path[2]}.json"
            end
          elsif path[0] == 'cookbooks'
            if path.length == 2
              raise ChefZero::DataStore::DataNotFoundError.new(path)
            elsif Chef::Config.versioned_cookbooks
              if path.length >= 3
                # cookbooks/name/version -> cookbooks/name-version
                path = [ path[0], "#{path[1]}-#{path[2]}" ] + path[3..-1]
              end
            else
              if path.length >= 3
                # cookbooks/name/version/... -> /cookbooks/name/... iff metadata says so
                version = get_single_cookbook_version(path)
                if path[2] == version
                  path = path[0..1] + path[3..-1]
                else
                  raise ChefZero::DataStore::DataNotFoundError.new(path)
                end
              end
            end
          elsif path.length == 2
            path = path.dup
            path[1] = "#{path[1]}.json"
          end
          path
        end

        def to_zero_path(entry)
          path = entry.path.split('/')
          if path[0] == 'data'
            path = path.dup
            path[0] = 'data_bags'
            if path.length >= 3
              path[2] = path[2][0..-6]
            end
          elsif path[0] == 'cookbooks'
            if Chef::Config.versioned_cookbooks
              # cookbooks/name-version/... -> cookbooks/name/version/...
              if path.length >= 2
                name, version = split_name_version(path[1])
                path = [ path[0], name, version ] + path[2..-1]
              end
            else
              if path.length >= 2
                # cookbooks/name/... -> cookbooks/name/version/...
                version = get_single_cookbook_version(path)
                path = path[0..1] + version + path[2..-1]
              end
            end
          elsif path.length == 2 && path[0] != 'cookbooks'
            path = path.dup
            path[1] = path[1][0..-6]
          end
          path
        end

        def to_leaf_name(entry)
          to_zero_path(entry)[-1]
        end

        def with_entry(path)
          begin
            yield Chef::ChefFS::FileSystem.resolve_path(chef_fs, path_to_chef_fs(path))
          rescue Chef::ChefFS::FileSystem::NotFoundError => e
            raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
          end
        end

        def with_dir(path)
          begin
            yield get_dir(_path_to_chef_fs(path), true)
          rescue Chef::ChefFS::FileSystem::NotFoundError => e
            raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
          end
        end

        def get_dir(path, create=false)
          result = Chef::FileSystem.resolve_path(chef_fs, path.join('/'))
          if result.exists?
            result
          elsif create
            get_dir(path[0..-2], create).create_child(result.name, nil)
          else
            raise ChefZero::DataStore::DataNotFoundError.new(path)
          end
        end

        def get_single_cookbook_version(path)
          dir = Chef::ChefFS::FileSystem.resolve_path(chef_fs, path[0..1].join('/'))
          metadata = ChefZero::CookbookData.metadata_from(dir, path[1], nil, [])
          metadata[:version] || '0.0.0'
        end
      end
    end
  end
end
