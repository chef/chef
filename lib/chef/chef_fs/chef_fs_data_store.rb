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

require "chef/cookbook_manifest"
require "chef_zero/data_store/memory_store"
require "chef_zero/data_store/data_already_exists_error"
require "chef_zero/data_store/data_not_found_error"
require "chef/chef_fs/file_pattern"
require "chef/chef_fs/file_system"
require "chef/chef_fs/file_system/not_found_error"
require "chef/chef_fs/file_system/memory/memory_root"
require "fileutils"

class Chef
  module ChefFS
    #
    # Translation layer between chef-zero's DataStore (a place where it expects
    # files to be stored) and ChefFS (the user's repository directory layout).
    #
    # chef-zero expects the data store to store files *its* way--for example, it
    # expects get("nodes/blah") to return the JSON text for the blah node, and
    # it expects get("cookbooks/blah/1.0.0") to return the JSON definition of
    # the blah cookbook version 1.0.0.
    #
    # The repository is defined the way the *user* wants their layout.  These
    # two things are very similar in layout (for example, nodes are stored under
    # the nodes/ directory and their filename is the name of the node).
    #
    # However, there are a few differences that make this more than just a raw
    # file store:
    #
    # 1. Cookbooks are stored much differently.
    #   - chef-zero places JSON text with the checksums for the cookbook at
    #     /cookbooks/NAME/VERSION, and expects the JSON to contain URLs to the
    #     actual files, which are stored elsewhere.
    #   - The repository contains an actual directory with just the cookbook
    #     files and a metadata.rb containing a version #.  There is no JSON to
    #     be found.
    #   - Further, if versioned_cookbooks is false, that directory is named
    #     /cookbooks/NAME and only one version exists.  If versioned_cookbooks
    #     is true, the directory is named /cookbooks/NAME-VERSION.
    #   - Therefore, ChefFSDataStore calculates the cookbook JSON by looking at
    #     the files in the cookbook and checksumming them, and reading metadata.rb
    #     for the version and dependency information.
    #   - ChefFSDataStore also modifies the cookbook file URLs so that they point
    #     to /file_store/repo/<filename> (the path to the actual file under the
    #     repository root).  For example, /file_store/repo/apache2/metadata.rb or
    #     /file_store/repo/cookbooks/apache2/recipes/default.rb).
    #
    # 2. Sandboxes don't exist in the repository.
    #   - ChefFSDataStore lets cookbooks be uploaded into a temporary memory
    #     storage, and when the cookbook is committed, copies the files onto the
    #     disk in the correct place (/cookbooks/apache2/recipes/default.rb).
    #
    # 3. Data bags:
    #   - The Chef server expects data bags in /data/BAG/ITEM
    #   - The repository stores data bags in /data_bags/BAG/ITEM
    #
    # 4. JSON filenames are generally NAME.json in the repository (e.g. /nodes/foo.json).
    #
    # 5. Org membership:
    #    chef-zero stores user membership in an org as a series of empty files.
    #    If an org has jkeiser and cdoherty as members, chef-zero expects these
    #    files to exist:
    #
    #    - `users/jkeiser` (content: '{}')
    #    - `users/cdoherty` (content: '{}')
    #
    #    ChefFS, on the other hand, stores user membership in an org as a single
    #    file, `members.json`, with content:
    #
    #        ```json
    #        [
    #          { "user": { "username": "jkeiser" } },
    #          { "user": { "username": "cdoherty" } }
    #        ]
    #        ```
    #
    #    To translate between the two, we need to intercept requests to `users`
    #    like so:
    #
    #    - `list(users)` -> `get(/members.json)`
    #    - `get(users/NAME)` -> `get(/members.json)`, see if it's in there
    #    - `create(users/NAME)` -> `get(/members.json)`, add name, `set(/members.json)`
    #    - `delete(users/NAME)` -> `get(/members.json)`, remove name, `set(/members.json)`
    #
    # 6. Org invitations:
    #    chef-zero stores org membership invitations as a series of empty files.
    #    If an org has invited jkeiser and cdoherty (and they have not yet accepted
    #    the invite), chef-zero expects these files to exist:
    #
    #    - `association_requests/jkeiser` (content: '{}')
    #    - `association_requests/cdoherty` (content: '{}')
    #
    #    ChefFS, on the other hand, stores invitations as a single file,
    #    `invitations.json`, with content:
    #
    #        ```json
    #        [
    #          { "id" => "jkeiser-chef", 'username' => 'jkeiser' },
    #          { "id" => "cdoherty-chef", 'username' => 'cdoherty' }
    #        ]
    #        ```
    #
    #    To translate between the two, we need to intercept requests to `users`
    #    like so:
    #
    #    - `list(association_requests)` -> `get(/invitations.json)`
    #    - `get(association_requests/NAME)` -> `get(/invitations.json)`, see if it's in there
    #    - `create(association_requests/NAME)` -> `get(/invitations.json)`, add name, `set(/invitations.json)`
    #    - `delete(association_requests/NAME)` -> `get(/invitations.json)`, remove name, `set(/invitations.json)`
    #
    class ChefFSDataStore

      # The base directories in a Chef Repo; even when these don't exist, a
      # matching GET for these objects will return an empty list instead of a
      # 404.
      BASE_DIRNAMES = %w{
        clients
        cookbooks
        data
        environments
        nodes
        roles
        users
        containers
        groups
        policy_groups
        policies
      }.freeze

      #
      # Create a new ChefFSDataStore
      #
      # ==== Arguments
      #
      # [chef_fs]
      #   A +ChefFS::FileSystem+ object representing the repository root.
      #   Generally will be a +ChefFS::FileSystem::ChefRepositoryFileSystemRoot+
      #   object, created from +ChefFS::Config.local_fs+.
      #
      def initialize(chef_fs, chef_config = Chef::Config)
        @chef_fs = chef_fs
        @memory_store = ChefZero::DataStore::MemoryStore.new
        @repo_mode = chef_config[:repo_mode]
      end

      def publish_description
        "Reading and writing data to #{chef_fs.fs_description}"
      end

      attr_reader :chef_fs
      attr_reader :repo_mode

      def create_dir(path, name, *options)
        if use_memory_store?(path)
          @memory_store.create_dir(path, name, *options)
        else
          with_parent_dir(path + [name], *options) do |parent, name|
            begin
              parent.create_child(name, nil)
            rescue Chef::ChefFS::FileSystem::AlreadyExistsError => e
              raise ChefZero::DataStore::DataAlreadyExistsError.new(to_zero_path(e.entry), e)
            end
          end
        end
      end

      #
      # If you want to get the contents of /data/x/y from the server,
      # you say chef_fs.child('data').child('x').child('y').read.
      # It will make exactly one network request: GET /data/x/y
      # And that will return 404 if it doesn't exist.
      #
      # ChefFS objects do not go to the network until you ask them for data.
      # This means you can construct a /data/x/y ChefFS entry early.
      #
      # Alternative:
      # chef_fs.child('data') could have done a GET /data preemptively,
      # allowing it to know whether child('x') was valid (GET /data gives you
      # a list of data bags). Then child('x') could have done a GET /data/x,
      # allowing it to know whether child('y') (the item) existed. Finally,
      # we would do the GET /data/x/y to read the contents. Three network
      # requests instead of 1.
      #

      def create(path, name, data, *options)
        if use_memory_store?(path)
          @memory_store.create(path, name, data, *options)

        elsif path[0] == "cookbooks" && path.length == 2
          # Do nothing.  The entry gets created when the cookbook is created.

        # /policy_groups/GROUP/policies/NAME
        elsif path[0] == "policy_groups" && path[2] == "policies"
          # Just set or create the proper entry in the hash
          update_json(to_chef_fs_path(path[0..1]), {}, *options) do |group|
            if policies.has_key?(path[3])
              raise ChefZero::DataStore::DataAlreadyExistsError.new(path, group)
            end

            group["policies"] ||= {}
            group["policies"][path[3]] = { "revision_id" => Chef::JSONCompat.parse(data) }
            group
          end

        # create [/organizations/ORG]/users/NAME (with content '{}')
        # Manipulate the `members.json` file that contains a list of all users
        elsif is_org? && path == [ "users" ]
          update_json("members.json", [], *options) do |members|
            # Format of each entry: { "user": { "username": "jkeiser" } }
            if members.any? { |member| member["user"]["username"] == name }
              raise ChefZero::DataStore::DataAlreadyExistsError.new(path, entry)
            end

            # Actually add the user
            members << { "user" => { "username" => name } }
          end

        # create [/organizations/ORG]/association_requests/NAME (with content '{}')
        # Manipulate the `invitations.json` file that contains a list of all users
        elsif is_org? && path == [ "association_requests" ]
          update_json("invitations.json", [], *options) do |invitations|
            # Format of each entry: { "id" => "jkeiser-chef", 'username' => 'jkeiser' }
            if invitations.any? { |member| member["username"] == name }
              raise ChefZero::DataStore::DataAlreadyExistsError.new(path)
            end

            # Actually add the user (TODO insert org name??)
            invitations << { "username" => name }
          end

        else
          if !data.is_a?(String)
            raise "set only works with strings"
          end

          with_parent_dir(path + [name], *options) do |parent, name|
            begin
              parent.create_child(name, data)
            rescue Chef::ChefFS::FileSystem::AlreadyExistsError => e
              raise ChefZero::DataStore::DataAlreadyExistsError.new(to_zero_path(e.entry), e)
            end
          end
        end
      end

      def get(path, request = nil)
        if use_memory_store?(path)
          @memory_store.get(path)

        elsif path[0] == "file_store" && path[1] == "repo"
          entry = Chef::ChefFS::FileSystem.resolve_path(chef_fs, path[2..-1].join("/"))
          begin
            entry.read
          rescue Chef::ChefFS::FileSystem::NotFoundError => e
            raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
          end

        # /policy_groups/NAME/policies/POLICYNAME: return the revision of the given policy
        elsif path[0] == "policy_groups" && path[2] == "policies" && path.length == 4
          # Just set or create the proper entry in the hash
          policy_group = get_json(to_chef_fs_path(path[0..1]), {})
          if !policy_group["policies"] || !policy_group["policies"][path[3]]
            raise ChefZero::DataStore::DataNotFoundError.new(path, entry)
          end
          # The policy group looks like:
          # {
          #   "policies": {
          #     "x": { "revision_id": "10" }
          #   }
          # }
          Chef::JSONCompat.to_json_pretty(policy_group["policies"][path[3]]["revision_id"])

        # GET [/organizations/ORG]/users/NAME -> /users/NAME
        # Manipulates members.json
        elsif is_org? && path[0] == "users" && path.length == 2
          if get_json("members.json", []).any? { |member| member["user"]["username"] == path[1] }
            "{}"
          else
            raise ChefZero::DataStore::DataNotFoundError.new(path)
          end

        # GET [/organizations/ORG]/association_requests/NAME -> /users/NAME
        # Manipulates invites.json
        elsif is_org? && path[0] == "association_requests" && path.length == 2
          if get_json("invites.json", []).any? { |member| member["user"]["username"] == path[1] }
            "{}"
          else
            raise ChefZero::DataStore::DataNotFoundError.new(path)
          end

        # GET /cookbooks/NAME/VERSION or /cookbook_artifacts/NAME/IDENTIFIER
        elsif %w{cookbooks cookbook_artifacts}.include?(path[0]) && path.length == 3
          with_entry(path) do |entry|
            cookbook_type = path[0]
            result = nil
            begin
              result = Chef::CookbookManifest.new(entry.chef_object, policy_mode: cookbook_type == "cookbook_artifacts").to_hash
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
            end

            result.each_pair do |key, value|
              if value.is_a?(Array)
                value.each do |file|
                  if file.is_a?(Hash) && file.has_key?("checksum")
                    relative = ["file_store", "repo", cookbook_type]
                    if chef_fs.versioned_cookbooks || cookbook_type == "cookbook_artifacts"
                      relative << "#{path[1]}-#{path[2]}"
                    else
                      relative << path[1]
                    end
                    relative = relative + file[:path].split("/")
                    file["url"] = ChefZero::RestBase.build_uri(request.base_uri, relative)
                  end
                end
              end
            end

            if cookbook_type == "cookbook_artifacts"
              result["metadata"] = result["metadata"].to_hash
              result["metadata"].delete_if do |key, value|
                value == [] ||
                  (value == {} && !%w{dependencies attributes recipes}.include?(key)) ||
                  (value == "" && %w{source_url issues_url}.include?(key)) ||
                  (value == false && key == "privacy")
              end
            end

            Chef::JSONCompat.to_json_pretty(result)
          end

        else
          with_entry(path) do |entry|
            begin
              entry.read
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
            end
          end
        end
      end

      def set(path, data, *options)
        if use_memory_store?(path)
          @memory_store.set(path, data, *options)
        else
          if !data.is_a?(String)
            raise "set only works with strings: #{path} = #{data.inspect}"
          end

          # Write out the files!
          if %w{cookbooks cookbook_artifacts}.include?(path[0]) && path.length == 3
            write_cookbook(path, data, *options)

          # Handle /policy_groups/some_policy_group/policies/some_policy_name
          elsif path[0] == "policy_groups" && path[2] == "policies" && path.length == 4
            # Just set or create the proper entry in the hash
            update_json(to_chef_fs_path(path[0..1]), {}, *options) do |group|
              group["policies"] ||= {}
              group["policies"][path[3]] = { "revision_id" => Chef::JSONCompat.parse(data) }
              group
            end

          else
            with_parent_dir(path, *options) do |parent, name|
              child = parent.child(name)
              if child.exists?
                child.write(data)
              else
                parent.create_child(name, data)
              end
            end
          end
        end
      end

      def delete(path)
        if use_memory_store?(path)
          @memory_store.delete(path)

        # DELETE /policy_groups/GROUP/policies/POLICY
        elsif path[0] == "policy_groups" && path[2] == "policies" && path.length == 4
          update_json(to_chef_fs_path(path[0..1]), {}) do |group|
            unless group["policies"] && group["policies"].has_key?(path[3])
              raise ChefZero::DataStore::DataNotFoundError.new(path)
            end
            group["policies"].delete(path[3])
            group
          end

        # DELETE [/organizations/ORG]/users/NAME
        # Manipulates members.json
        elsif is_org? && path[0] == "users" && path.length == 2
          update_json("members.json", []) do |members|
            result = members.reject { |member| member["user"]["username"] == path[1] }
            if result.size == members.size
              raise ChefZero::DataStore::DataNotFoundError.new(path)
            end
            result
          end

        # DELETE [/organizations/ORG]/users/NAME
        # Manipulates members.json
        elsif is_org? && path[0] == "association_requests" && path.length == 2
          update_json("invitations.json", []) do |invitations|
            result = invitations.reject { |invitation| invitation["username"] == path[1] }
            if result.size == invitations.size
              raise ChefZero::DataStore::DataNotFoundError.new(path)
            end
            result
          end

        else
          with_entry(path) do |entry|
            begin
              if %w{cookbooks cookbook_artifacts}.include?(path[0]) && path.length >= 3
                entry.delete(true)
              else
                entry.delete(false)
              end
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
            end
          end
        end
      end

      def delete_dir(path, *options)
        if use_memory_store?(path)
          @memory_store.delete_dir(path, *options)

        # DELETE /policies/POLICY
        elsif path[0] == "policies" && path.length == 2
          with_entry(path[0..0]) do |policies|
            # /policies:
            #   - a-1.0.0.json
            #   - a-1.0.1.json
            #   - b-2.0.0.json
            found_policy = false
            policies.children.each do |policy|
              # We want to delete just the ones that == POLICY
              next unless policy.name.rpartition("-")[0] == path[1]
              policy.delete(false)
              found_policy = true
            end
            raise ChefZero::DataStore::DataNotFoundError.new(path) if !found_policy
          end

        else
          with_entry(path) do |entry|
            begin
              entry.delete(options.include?(:recursive))
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
            end
          end
        end
      end

      def list(path)
        if use_memory_store?(path)
          @memory_store.list(path)

        # LIST /policies
        elsif path == [ "policies" ]
          with_entry([ path[0] ]) do |policies|
            begin
              policies.children.map { |policy| policy.name[0..-6].rpartition("-")[0] }.uniq
            rescue Chef::ChefFS::FileSystem::NotFoundError
              []
            end
          end

        # LIST /policies/POLICY/revisions
        elsif path[0] == "policies" && path[2] == "revisions" && path.length == 3
          with_entry([ path[0] ]) do |policies|
            # /policies:
            #   - a-1.0.0.json
            #   - a-1.0.1.json
            #   - b-2.0.0.json
            revisions = []
            policies.children.each do |policy|
              name, dash, revision = policy.name[0..-6].rpartition("-")
              revisions << revision if name == path[1]
            end
            raise ChefZero::DataStore::DataNotFoundError.new(path) if revisions.empty?
            revisions
          end

        elsif path[0] == "policy_groups" && path.length == 2
          with_entry(path) do |entry|
            [ "policies" ]
          end

        elsif path[0] == "policy_groups" && path[2] == "policies" && path.length == 3
          with_entry(path[0..1]) do |entry|
            policies = Chef::JSONCompat.parse(entry.read)["policies"] || {}
            policies.keys
          end

        elsif %w{cookbooks cookbook_artifacts}.include?(path[0]) && path.length == 1
          with_entry(path) do |entry|
            begin
              if path[0] == "cookbook_artifacts"
                entry.children.map { |child| child.name.rpartition("-")[0] }.uniq
              elsif chef_fs.versioned_cookbooks
                # /cookbooks/name-version -> /cookbooks/name
                entry.children.map { |child| split_name_version(child.name)[0] }.uniq
              else
                entry.children.map { |child| child.name }
              end
            rescue Chef::ChefFS::FileSystem::NotFoundError
              # If the cookbooks dir doesn't exist, we have no cookbooks (not 404)
              []
            end
          end

        elsif %w{cookbooks cookbook_artifacts}.include?(path[0]) && path.length == 2
          if chef_fs.versioned_cookbooks || path[0] == "cookbook_artifacts"
            result = with_entry([ path[0] ]) do |entry|
              # list /cookbooks/name = filter /cookbooks/name-version down to name
              entry.children.map { |child| split_name_version(child.name) }.
              select { |name, version| name == path[1] }.
              map { |name, version| version }
            end
            if result.empty?
              raise ChefZero::DataStore::DataNotFoundError.new(path)
            end
            result
          else
            # list /cookbooks/name = <single version>
            version = get_single_cookbook_version(path)
            [version]
          end

        else
          result = with_entry(path) do |entry|
            begin
              entry.children.map { |c| zero_filename(c) }.sort
            rescue Chef::ChefFS::FileSystem::NotFoundError => e
              # /cookbooks, /data, etc. never return 404
              if path_always_exists?(path)
                []
              else
                raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
              end
            end
          end

          # Older versions of chef-zero do not understand policies and cookbook_artifacts,
          # don't give that stuff to them
          if path == [] && ChefZero::VERSION.to_f < 4.4
            result.reject! { |child| %w{policies policy_data cookbook_artifacts}.include?(child) }
          end
          result
        end
      end

      def exists?(path)
        if use_memory_store?(path)
          @memory_store.exists?(path)

        # /policy_groups/NAME/policies/POLICYNAME
        elsif path[0] == "policy_groups" && path[2] == "policies" && path.length == 4
          group = get_json(to_chef_fs_path(path[0..1]), {})
          group["policies"] && group["policies"].has_key?(path[3])

        else
          path_always_exists?(path) || Chef::ChefFS::FileSystem.resolve_path(chef_fs, to_chef_fs_path(path)).exists?
        end
      end

      def exists_dir?(path)
        if use_memory_store?(path)
          @memory_store.exists_dir?(path)

        elsif %w{cookbooks cookbook_artifacts}.include?(path[0]) && path.length == 2
          list([ path[0] ]).include?(path[1])

        # /policies/NAME
        elsif path[0] == "policies" && path.length == 2
          list([ path[0] ]).include?(path[1])

        # /policy_groups/NAME/policies
        elsif path[0] == "policy_groups" && path[2] == "policies" && path.length == 3
          exists_dir?(path[0..1])

        else
          Chef::ChefFS::FileSystem.resolve_path(chef_fs, to_chef_fs_path(path)).exists?
        end
      end

      private

      def use_memory_store?(path)
        return path[0] == "sandboxes" || path[0] == "file_store" && path[1] == "checksums" || path == %w{environments _default}
      end

      def write_cookbook(path, data, *options)
        cookbook_type = path[0]
        if chef_fs.versioned_cookbooks
          cookbook_path = File.join(cookbook_type, "#{path[1]}-#{path[2]}")
        else
          cookbook_path = File.join(cookbook_type, path[1])
        end

        # Create a little Chef::ChefFS memory filesystem with the data
        cookbook_fs = Chef::ChefFS::FileSystem::Memory::MemoryRoot.new("uploading")
        cookbook = Chef::JSONCompat.parse(data)
        cookbook.each_pair do |key, value|
          if value.is_a?(Array)
            value.each do |file|
              if file.is_a?(Hash) && file.has_key?("checksum")
                file_data = @memory_store.get(["file_store", "checksums", file["checksum"]])
                cookbook_fs.add_file(File.join(cookbook_path, file["path"]), file_data)
              end
            end
          end
        end

        # Create the .uploaded-cookbook-version.json
        cookbooks = chef_fs.child(cookbook_type)
        if !cookbooks.exists?
          cookbooks = chef_fs.create_child(cookbook_type)
        end
        # We are calling a cookbooks-specific API, so get multiplexed_dirs out of the way if it is there
        if cookbooks.respond_to?(:multiplexed_dirs)
          cookbooks = cookbooks.write_dir
        end
        cookbooks.write_cookbook(cookbook_path, data, cookbook_fs)
      end

      def split_name_version(entry_name)
        name_version = entry_name.split("-")
        name = name_version[0..-2].join("-")
        version = name_version[-1]
        [name, version]
      end

      def to_chef_fs_path(path)
        _to_chef_fs_path(path).join("/")
      end

      def chef_fs_filename(path)
        _to_chef_fs_path(path)[-1]
      end

      def _to_chef_fs_path(path)
        path = path.dup

        # /data -> /data_bags
        # /data/BAG -> /data_bags/BAG
        # /data/BAG/ITEM -> /data_bags/BAG/ITEM.json
        if path[0] == "data"
          path[0] = "data_bags"
          if path.length >= 3
            path[2] = "#{path[2]}.json"
          end

        # /client_keys/CLIENT/keys -> /client_keys/CLIENT
        # /client_keys/CLIENT/keys/KEYNAME -> /client_keys/CLIENT/KEYNAME.json
        elsif path[0] == "client_keys"
          path.delete_at(2)
          if path.length >= 3
            path[-1] += ".json"
          end

        # /policies/POLICY/revisions/REVISION -> /policies/POLICY-REVISION.json
        elsif path[0] == "policies" && path[2] == "revisions" && path.length >= 4
          path = [ "policies", "#{path[1]}-#{path[3]}.json" ]

        elsif %w{cookbooks cookbook_artifacts}.include?(path[0])
          if path.length == 2
            raise ChefZero::DataStore::DataNotFoundError.new(path)
          elsif path.length >= 3
            if chef_fs.versioned_cookbooks || path[0] == "cookbook_artifacts"
              # cookbooks/name/version -> cookbooks/name-version
              path = [ path[0], "#{path[1]}-#{path[2]}" ] + path[3..-1]
            else
              # cookbooks/name/version/... -> /cookbooks/name/... iff metadata says so
              version = get_single_cookbook_version(path)
              if path[2] == version
                path = path[0..1] + path[3..-1]
              else
                raise ChefZero::DataStore::DataNotFoundError.new(path)
              end
            end
          end

        elsif path[0] == "acls"
          # /acls/data -> /acls/data_bags
          if path[1] == "data"
            path[1] = "data_bags"
          end

          # /acls/containers|nodes|.../x.json
          # /acls/organization.json
          if path.length == 3 || path == %w{acls organization}
            path[-1] = "#{path[-1]}.json"
          end

          # /acls/containers|nodes|... do NOT drop into the next elsif, and do
          # not get .json appended

        # /nodes|clients|.../x.json
        elsif path.length == 2
          path[-1] = "#{path[-1]}.json"
        end
        path
      end

      def to_zero_path(entry)
        path = entry.path.split("/")[1..-1]

        if path[0] == "data_bags"
          path[0] = "data"
          if path.length >= 3
            path[2] = path[2][0..-6]
          end

        # /client_keys/CLIENT -> /client_keys/CLIENT/keys
        # /client_keys/CLIENT/KEYNAME.json -> /client_keys/CLIENT/keys/KEYNAME
        elsif path[0] == "client_keys"
          if path.size == 2
            path << "keys"
          elsif path.size > 2
            path[2..-1] = [ "keys", path[-1][0..-6] ]
          end

        elsif %w{cookbooks cookbook_artifacts}.include?(path[0])
          if chef_fs.versioned_cookbooks || path[0] == "cookbook_artifacts"
            # cookbooks/name-version/... -> cookbooks/name/version/...
            if path.length >= 2
              name, version = split_name_version(path[1])
              path = [ path[0], name, version ] + path[2..-1]
            end
          else
            if path.length >= 2
              # cookbooks/name/... -> cookbooks/name/version/...
              version = get_single_cookbook_version(path)
              path = path[0..1] + [version] + path[2..-1]
            end
          end

        # /policies/NAME-REVISION.json -> /policies/NAME/revisions/REVISION
        elsif path[0] == "policies"
          if path.length >= 2
            name, dash, revision = path[1][0..-6].rpartition("-")
            path = [ "policies", name, "revisions", revision ]
          end

        elsif path.length == 2 && path[0] != "cookbooks"
          path[1] = path[1][0..-6]
        end

        path
      end

      def zero_filename(entry)
        to_zero_path(entry)[-1]
      end

      def path_always_exists?(path)
        return path.length == 1 && BASE_DIRNAMES.include?(path[0])
      end

      def with_entry(path)
        begin
          yield Chef::ChefFS::FileSystem.resolve_path(chef_fs, to_chef_fs_path(path))
        rescue Chef::ChefFS::FileSystem::NotFoundError => e
          raise ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
        end
      end

      def with_parent_dir(path, *options)
        path = _to_chef_fs_path(path)
        begin
          yield get_dir(path[0..-2], options.include?(:create_dir)), path[-1]
        rescue Chef::ChefFS::FileSystem::NotFoundError => e
          err = ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
          err.set_backtrace(e.backtrace)
          raise err
        end
      end

      def with_dir(path)
        # Do not automatically create data bags
        create = !(path[0] == "data" && path.size >= 2)

        begin
          yield get_dir(_to_chef_fs_path(path), create)
        rescue Chef::ChefFS::FileSystem::NotFoundError => e
          err = ChefZero::DataStore::DataNotFoundError.new(to_zero_path(e.entry), e)
          err.set_backtrace(e.backtrace)
          raise err
        end
      end

      def get_dir(path, create = false)
        result = Chef::ChefFS::FileSystem.resolve_path(chef_fs, path.join("/"))
        if result.exists?
          result
        elsif create || path.size == 1
          get_dir(path[0..-2], create).create_child(result.name, nil)
        else
          raise ChefZero::DataStore::DataNotFoundError.new(path)
        end
      end

      def get_single_cookbook_version(path)
        dir = Chef::ChefFS::FileSystem.resolve_path(chef_fs, path[0..1].join("/"))
        metadata = ChefZero::CookbookData.metadata_from(dir, path[1], nil, [])
        metadata[:version] || "0.0.0"
      end

      def update_json(path, default_value, *options)
        entry = Chef::ChefFS::FileSystem.resolve_path(chef_fs, path)
        begin
          input = Chef::JSONCompat.parse(entry.read)
          output = yield input
          entry.write(Chef::JSONCompat.to_json_pretty(output)) if output != Chef::JSONCompat.parse(entry.read)
        rescue Chef::ChefFS::FileSystem::NotFoundError
          # Send the default value to the caller, and create the entry if the caller updates it
          output = yield default_value
          parent = entry.parent
          parent = ensure_dir(parent) if options.include?(:create_dir)
          parent.create_child(entry.name, Chef::JSONCompat.to_json_pretty(output)) if output != []
        end
      end

      def ensure_dir(entry)
        return entry if entry.exists?
        parent = entry.parent
        if parent
          ensure_dir(parent)
          parent.create_child(entry.name)
        end
      end

      def get_json(path, default_value)
        entry = Chef::ChefFS::FileSystem.resolve_path(chef_fs, path)
        begin
          Chef::JSONCompat.parse(entry.read)
        rescue Chef::ChefFS::FileSystem::NotFoundError
          default_value
        end
      end

      def is_org?
        repo_mode == "hosted_everything"
      end
    end
  end
end
