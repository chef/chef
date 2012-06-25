require 'spec_helper'
require 'chef/cookbook/synchronizer'
require 'chef/cookbook_version'

describe Chef::CookbookCacheCleaner do
  describe "when cleaning up unused cookbook components" do

    before do
      @cleaner = Chef::CookbookCacheCleaner.instance
      @cleaner.reset!
    end

    it "removes all files that belong to unused cookbooks" do
    end

    it "removes all files not validated during the chef run" do
      file_cache = mock("Chef::FileCache with files from unused cookbooks")
      unused_template_files = %w{cookbooks/unused/templates/default/foo.conf.erb cookbooks/unused/tempaltes/default/bar.conf.erb}
      valid_cached_cb_files = %w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb}
      @cleaner.mark_file_as_valid('cookbooks/valid1/recipes/default.rb')
      @cleaner.mark_file_as_valid('cookbooks/valid2/recipes/default.rb')
      file_cache.should_receive(:find).with(File.join(%w{cookbooks ** *})).and_return(valid_cached_cb_files + unused_template_files)
      file_cache.should_receive(:delete).with('cookbooks/unused/templates/default/foo.conf.erb')
      file_cache.should_receive(:delete).with('cookbooks/unused/tempaltes/default/bar.conf.erb')
      cookbook_hash = {"valid1"=> {}, "valid2" => {}}
      @cleaner.stub!(:cache).and_return(file_cache)
      @cleaner.cleanup_file_cache
    end

    describe "on chef-solo" do
      before do
        Chef::Config[:solo] = true
      end

      after do
        Chef::Config[:solo] = false
      end

      it "does not remove anything" do
        @cleaner.cache.stub!(:find).and_return(%w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb})
        @cleaner.cache.should_not_receive(:delete)
        @cleaner.cleanup_file_cache
      end

    end

  end
end

describe Chef::CookbookSynchronizer do
  before do
    segments = [ :resources, :providers, :recipes, :definitions, :libraries, :attributes, :files, :templates, :root_files ]
    @cookbook_manifest = {}
    @cookbook_a = Chef::CookbookVersion.new("cookbook_a")
    @cookbook_a_manifest = segments.inject({}) {|h, segment| h[segment.to_s] = []; h}
    @cookbook_a_default_recipe = { "path" => "recipes/default.rb",
                                   "url"  => "http://chef.example.com/abc123",
                                   "checksum" => "abc123" }
    @cookbook_a_manifest["recipes"] = [ @cookbook_a_default_recipe ]

    @cookbook_a_default_attrs  = { "path" => "attributes/default.rb",
                                   "url"  => "http://chef.example.com/abc456",
                                   "checksum" => "abc456" }
    @cookbook_a_manifest["attributes"] = [ @cookbook_a_default_attrs ]
    @cookbook_a_manifest["templates"] = [{"path" => "templates/default/apache2.conf.erb", "url" => "http://chef.example.com/ffffff"}]
    @cookbook_a.manifest = @cookbook_a_manifest
    @cookbook_manifest["cookbook_a"] = @cookbook_a

    @events = Chef::EventDispatch::Dispatcher.new
    @synchronizer = Chef::CookbookSynchronizer.new(@cookbook_manifest, @events)
  end

  it "lists the cookbook names" do
    @synchronizer.cookbook_names.should == %w[cookbook_a]
  end

  it "lists the cookbook manifests" do
    @synchronizer.cookbooks.should == [@cookbook_a]
  end

  context "when the cache contains unneeded cookbooks" do
    before do
      @file_cache = mock("Chef::FileCache with files from unused cookbooks")
      @valid_cached_cb_files = %w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb}
      @obsolete_cb_files = %w{cookbooks/old1/recipes/default.rb cookbooks/old2/recipes/default.rb}

      @cookbook_hash = {"valid1"=> {}, "valid2" => {}}

      @synchronizer = Chef::CookbookSynchronizer.new(@cookbook_hash, @events)
    end

    it "removes unneeded cookbooks" do
      @file_cache.should_receive(:find).with(File.join(%w{cookbooks ** *})).and_return(@valid_cached_cb_files + @obsolete_cb_files)
      @file_cache.should_receive(:delete).with('cookbooks/old1/recipes/default.rb')
      @file_cache.should_receive(:delete).with('cookbooks/old2/recipes/default.rb')
      @synchronizer.stub!(:cache).and_return(@file_cache)
      @synchronizer.clear_obsoleted_cookbooks
    end
  end

  describe "when syncing cookbooks with the server" do
    before do
      # Would rather not stub out methods on the test subject, but setting up
      # the state is a PITA and tests for this behavior are above.
      @synchronizer.should_receive(:clear_obsoleted_cookbooks)

      @server_api = mock("Chef::REST (mock)")
      @file_cache = mock("Chef::FileCache (mock)")
      @synchronizer.stub!(:server_api).and_return(@server_api)
      @synchronizer.stub!(:cache).and_return(@file_cache)


      @cookbook_a_default_recipe_tempfile = mock("Tempfile for cookbook_a default.rb recipe",
                                                 :path => "/tmp/cookbook_a_recipes_default_rb")

      @cookbook_a_default_attribute_tempfile = mock("Tempfile for cookbook_a default.rb attr file",
                                                 :path => "/tmp/cookbook_a_attributes_default_rb")

    end

    context "when the cache does not contain the desired files" do
      before do

        # Files are not in the cache:
        @file_cache.should_receive(:has_key?).
          with("cookbooks/cookbook_a/recipes/default.rb").
          and_return(false)
        @file_cache.should_receive(:has_key?).
          with("cookbooks/cookbook_a/attributes/default.rb").
          and_return(false)

        # Fetch and copy default.rb recipe
        @server_api.should_receive(:get_rest).
          with('http://chef.example.com/abc123', true).
          and_return(@cookbook_a_default_recipe_tempfile)
        @file_cache.should_receive(:move_to).
          with("/tmp/cookbook_a_recipes_default_rb", "cookbooks/cookbook_a/recipes/default.rb")
        @file_cache.should_receive(:load).
          with("cookbooks/cookbook_a/recipes/default.rb", false).
          and_return("/file-cache/cookbooks/cookbook_a/recipes/default.rb")

        # Fetch and copy default.rb attribute file
        @server_api.should_receive(:get_rest).
          with('http://chef.example.com/abc456', true).
          and_return(@cookbook_a_default_attribute_tempfile)
        @file_cache.should_receive(:move_to).
          with("/tmp/cookbook_a_attributes_default_rb", "cookbooks/cookbook_a/attributes/default.rb")
        @file_cache.should_receive(:load).
          with("cookbooks/cookbook_a/attributes/default.rb", false).
          and_return("/file-cache/cookbooks/cookbook_a/attributes/default.rb")
      end

      it "fetches eagerly loaded files" do
        @synchronizer.sync_cookbooks
      end

      it "does not fetch templates or cookbook files" do
        # Implicitly tested in previous test; this test is just for behavior specification.
        @server_api.should_not_receive(:get_rest).
          with('http://chef.example.com/ffffff', true)

        @synchronizer.sync_cookbooks
      end

    end

    context "when the cache contains outdated files" do
      before do
        # Files are in the cache:
        @file_cache.should_receive(:has_key?).
          with("cookbooks/cookbook_a/recipes/default.rb").
          and_return(true)
        @file_cache.should_receive(:has_key?).
          with("cookbooks/cookbook_a/attributes/default.rb").
          and_return(true)


        # Fetch and copy default.rb recipe
        @server_api.should_receive(:get_rest).
          with('http://chef.example.com/abc123', true).
          and_return(@cookbook_a_default_recipe_tempfile)
        @file_cache.should_receive(:move_to).
          with("/tmp/cookbook_a_recipes_default_rb", "cookbooks/cookbook_a/recipes/default.rb")
        @file_cache.should_receive(:load).
          with("cookbooks/cookbook_a/recipes/default.rb", false).
          twice.
          and_return("/file-cache/cookbooks/cookbook_a/recipes/default.rb")

        # Current file has fff000, want abc123
        Chef::CookbookVersion.should_receive(:checksum_cookbook_file).
          with("/file-cache/cookbooks/cookbook_a/recipes/default.rb").
          and_return("fff000")

        # Fetch and copy default.rb attribute file
        @server_api.should_receive(:get_rest).
          with('http://chef.example.com/abc456', true).
          and_return(@cookbook_a_default_attribute_tempfile)
        @file_cache.should_receive(:move_to).
          with("/tmp/cookbook_a_attributes_default_rb", "cookbooks/cookbook_a/attributes/default.rb")
        @file_cache.should_receive(:load).
          with("cookbooks/cookbook_a/attributes/default.rb", false).
          twice.
          and_return("/file-cache/cookbooks/cookbook_a/attributes/default.rb")

        # Current file has fff000, want abc456
        Chef::CookbookVersion.should_receive(:checksum_cookbook_file).
          with("/file-cache/cookbooks/cookbook_a/attributes/default.rb").
          and_return("fff000")
      end

      it "updates the outdated files" do
        @synchronizer.sync_cookbooks
      end
    end

    context "when the cache is up to date" do
      before do
        # Files are in the cache:
        @file_cache.should_receive(:has_key?).
          with("cookbooks/cookbook_a/recipes/default.rb").
          and_return(true)
        @file_cache.should_receive(:has_key?).
          with("cookbooks/cookbook_a/attributes/default.rb").
          and_return(true)

        # Current file has abc123, want abc123
        Chef::CookbookVersion.should_receive(:checksum_cookbook_file).
          with("/file-cache/cookbooks/cookbook_a/recipes/default.rb").
          and_return("abc123")

        # Current file has abc456, want abc456
        Chef::CookbookVersion.should_receive(:checksum_cookbook_file).
          with("/file-cache/cookbooks/cookbook_a/attributes/default.rb").
          and_return("abc456")

        @file_cache.should_receive(:load).
          with("cookbooks/cookbook_a/recipes/default.rb", false).
          twice.
          and_return("/file-cache/cookbooks/cookbook_a/recipes/default.rb")

        @file_cache.should_receive(:load).
          with("cookbooks/cookbook_a/attributes/default.rb", false).
          twice.
          and_return("/file-cache/cookbooks/cookbook_a/attributes/default.rb")
      end

      it "does not update files" do
        @file_cache.should_not_receive(:move_to)
        @server_api.should_not_receive(:get_rest)
        @synchronizer.sync_cookbooks
      end

    end

  end

end

