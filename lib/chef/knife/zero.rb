require 'chef/chef_fs/knife'
require 'chef_zero/server'
require 'chef_zero/data_store/memory_store'

# For ChefFSStore
require 'chef/chef_fs/file_system'
require 'chef/chef_fs/file_system/not_found_error'
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
          @memory_fs = ChefZero::DataStore::MemoryStore.new
        end

        attr_reader :chef_fs

        MEMORY_PATHS = %w(sandboxes file_store cookbooks)

        # TODO carve out a space for cookbooks

        def create_dir(path, name, *options)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.create_dir(path, name, *options)
          else
            path = fix_path(path)

            parent = get_dir(path, options.include?(:create_dir))
            parent.create_child(name, nil)
          end
        end

        def create(path, name, data, *options)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.create(path, name, data, *options)
          else
            path = fix_path(path)

            if !data.is_a?(String)
              raise "set only works with strings"
            end

            parent = get_dir(path, options.include?(:create_dir))
            parent.create_child("#{name}.json", data)
          end
        end

        def get(path)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.get(path)
          else
            path = fix_path(path)

            begin
              Chef::ChefFS::FileSystem.resolve_path(chef_fs, "#{path.join('/')}.json").read
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(path, e)
            end
          end
        end

        def set(path, data, *options)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.set(path, data, *options)
          else
            path = fix_path(path)

            if !data.is_a?(String)
              raise "set only works with strings: #{path} = #{data.inspect}"
            end

            parent = get_dir(path[0..-2], options.include?(:create_dir))
            parent.create_child("#{path[-1]}.json", data)
          end
        end

        def delete(path)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.delete(path)
          else
            path = fix_path(path)

            begin
              Chef::ChefFS::FileSystem.resolve_path(chef_fs, "#{path.join('/')}.json").delete
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(path, e)
            end
          end
        end

        def delete_dir(path, *options)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.delete_dir(path, *options)
          else
            path = fix_path(path)

            begin
              Chef::ChefFS::FileSystem.resolve_path(chef_fs, path.join('/')).delete(options.include?(:recursive))
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(path, e)
            end
          end
        end

        def list(path)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.list(path)
          else
            path = fix_path(path)

            begin
              Chef::ChefFS::FileSystem.resolve_path(chef_fs, path.join('/')).children.map { |c| remove_dot_json(c) }.sort
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(path, e)
            end
          end
        end

        def exists?(path)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.exists?(path)
          else
            path = fix_path(path)

            Chef::ChefFS::FileSystem.resolve_path(chef_fs, "#{path.join('/')}.json").exists?
          end
        end

        def exists_dir?(path)
          if MEMORY_PATHS.include?(path[0])
            @memory_fs.exists_dir?(path)
          else
            path = fix_path(path)

            Chef::ChefFS::FileSystem.resolve_path(chef_fs, path.join('/')).exists?
          end
        end

        private

        def fix_path(path)
          if path[0] == 'data'
            path = path.dup
            path[0] = 'data_bags'
          end
          path
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

        def remove_dot_json(entry)
          if entry.dir?
            entry.name
          else
            entry.name[0..-6]
          end
        end
      end
    end
  end
end
