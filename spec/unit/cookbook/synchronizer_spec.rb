require "spec_helper"
require "chef/cookbook/synchronizer"
require "chef/cookbook_version"

describe Chef::CookbookCacheCleaner do
  describe "when cleaning up unused cookbook components" do

    let(:cleaner) do
      cleaner = Chef::CookbookCacheCleaner.instance
      cleaner.reset!
      cleaner
    end

    let(:file_cache) { double("Chef::FileCache with files from unused cookbooks") }

    let(:unused_template_files) do
      %w{
        cookbooks/unused/templates/default/foo.conf.erb
        cookbooks/unused/tempaltes/default/bar.conf.erb
      }
    end

    let(:valid_cached_cb_files) do
      %w{
        cookbooks/valid1/recipes/default.rb
        cookbooks/valid2/recipes/default.rb
      }
    end

    before do
      valid_cached_cb_files.each do |cbf|
        cleaner.mark_file_as_valid(cbf)
      end
    end

    it "removes all files not validated during the chef run" do
      expect(file_cache).to receive(:find).with(File.join(%w{cookbooks ** {*,.*}})).and_return(valid_cached_cb_files + unused_template_files)
      unused_template_files.each do |cbf|
        expect(file_cache).to receive(:delete).with(cbf)
      end
      allow(cleaner).to receive(:cache).and_return(file_cache)
      cleaner.cleanup_file_cache
    end

    it "does not remove anything when skip_removal is true" do
      cleaner.skip_removal = true
      allow(cleaner.cache).to receive(:find).and_return(%w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb})
      expect(cleaner.cache).not_to receive(:delete)
      cleaner.cleanup_file_cache
    end

    it "does not remove anything on chef-solo" do
      Chef::Config[:solo_legacy_mode] = true
      allow(cleaner.cache).to receive(:find).and_return(%w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb})
      expect(cleaner.cache).not_to receive(:delete)
      cleaner.cleanup_file_cache
    end
  end
end

describe Chef::CookbookSynchronizer do
  let(:cookbook_a_default_recipe) do
    {
      "path" => "recipes/default.rb",
      "name" => "recipes/default.rb",
      "url"  => "http://chef.example.com/abc123",
      "checksum" => "abc123",
    }
  end

  let(:cookbook_a_default_attrs) do
    {
      "path" => "attributes/default.rb",
      "name" => "attributes/default.rb",
      "url"  => "http://chef.example.com/abc456",
      "checksum" => "abc456",
    }
  end

  let(:cookbook_a_template) do
    {
      "path" => "templates/default/apache2.conf.erb",
      "name" => "templates/apache2.conf.erb",
      "url" => "http://chef.example.com/ffffff",
      "checksum" => "abc125",
    }
  end

  let(:cookbook_a_file) do
    {
      "path" => "files/default/megaman.conf",
      "name" => "files/megaman.conf",
      "url" => "http://chef.example.com/megaman.conf",
      "checksum" => "abc124",
    }
  end

  let(:cookbook_a_manifest) do
    cookbook_a_manifest = { all_files: [ cookbook_a_default_recipe, cookbook_a_default_attrs, cookbook_a_template, cookbook_a_file ] }
    cookbook_a_manifest
  end

  let(:cookbook_a) do
    cookbook_a = Chef::CookbookVersion.new("cookbook_a")
    cookbook_a.manifest = cookbook_a_manifest
    cookbook_a
  end

  let(:cookbook_manifest) do
    {
      "cookbook_a" => cookbook_a,
    }
  end

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:no_lazy_load) { true }

  let(:synchronizer) do
    Chef::Config[:no_lazy_load] = no_lazy_load
    Chef::Config[:file_cache_path] = "/file-cache"
    Chef::CookbookSynchronizer.new(cookbook_manifest, events)
  end

  it "lists the cookbook names" do
    expect(synchronizer.cookbook_names).to eq(%w{cookbook_a})
  end

  it "lists the cookbook manifests" do
    expect(synchronizer.cookbooks).to eq([cookbook_a])
  end

  context "#clear_obsoleted_cookbooks" do
    after do
      # Singletons == Global State == Bad
      Chef::CookbookCacheCleaner.instance.skip_removal = nil
    end

    it "behaves correctly when remove_obsoleted_files is false" do
      synchronizer.remove_obsoleted_files = false
      expect(synchronizer).not_to receive(:remove_old_cookbooks)
      expect(synchronizer).to receive(:remove_deleted_files)
      synchronizer.clear_obsoleted_cookbooks
      expect(Chef::CookbookCacheCleaner.instance.skip_removal).to be true
    end

    it "behaves correctly when remove_obsoleted_files is true" do
      synchronizer.remove_obsoleted_files = true
      expect(synchronizer).to receive(:remove_old_cookbooks)
      expect(synchronizer).to receive(:remove_deleted_files)
      synchronizer.clear_obsoleted_cookbooks
      expect(Chef::CookbookCacheCleaner.instance.skip_removal).to be nil
    end
  end

  context "#remove_old_cookbooks" do
    let(:file_cache) { double("Chef::FileCache with files from unused cookbooks") }

    let(:cookbook_manifest) do
      { "valid1" => {}, "valid2" => {} }
    end

    it "removes unneeded cookbooks" do
      valid_cached_cb_files = %w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb}
      obsolete_cb_files = %w{cookbooks/old1/recipes/default.rb cookbooks/old2/recipes/default.rb}
      expect(file_cache).to receive(:find).with(File.join(%w{cookbooks ** {*,.*}})).and_return(valid_cached_cb_files + obsolete_cb_files)
      expect(file_cache).to receive(:delete).with("cookbooks/old1/recipes/default.rb")
      expect(file_cache).to receive(:delete).with("cookbooks/old2/recipes/default.rb")
      allow(synchronizer).to receive(:cache).and_return(file_cache)
      synchronizer.remove_old_cookbooks
    end
  end

  context "#remove_deleted_files" do
    let(:file_cache) { double("Chef::FileCache with files from unused cookbooks") }

    let(:cookbook_manifest) do
      { "valid1" => {}, "valid2" => {} }
    end

    it "removes only deleted files" do
      valid_cached_cb_files = %w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb}
      obsolete_cb_files = %w{cookbooks/valid1/recipes/deleted.rb cookbooks/valid2/recipes/deleted.rb}
      expect(file_cache).to receive(:find).with(File.join(%w{cookbooks ** {*,.*}})).and_return(valid_cached_cb_files + obsolete_cb_files)
      # valid1 is a cookbook in our run_list
      expect(synchronizer).to receive(:have_cookbook?).with("valid1").at_least(:once).and_return(true)
      # valid2 is a cookbook not in our run_list (we're simulating an override run_list where valid2 needs to be preserved)
      expect(synchronizer).to receive(:have_cookbook?).with("valid2").at_least(:once).and_return(false)
      expect(file_cache).to receive(:delete).with("cookbooks/valid1/recipes/deleted.rb")
      expect(synchronizer).to receive(:cookbook_segment).with("valid1", "recipes").at_least(:once).and_return([ { "path" => "recipes/default.rb" }])
      allow(synchronizer).to receive(:cache).and_return(file_cache)
      synchronizer.remove_deleted_files
    end
  end

  let(:cookbook_a_default_recipe_tempfile) do
    double("Tempfile for cookbook_a default.rb recipe",
           :path => "/tmp/cookbook_a_recipes_default_rb")
  end

  let(:cookbook_a_default_attribute_tempfile) do
    double("Tempfile for cookbook_a default.rb attr file",
           :path => "/tmp/cookbook_a_attributes_default_rb")
  end

  let(:cookbook_a_file_default_tempfile) do
    double("Tempfile for cookbook_a megaman.conf file",
           :path => "/tmp/cookbook_a_file_default_tempfile")
  end

  let(:cookbook_a_template_default_tempfile) do
    double("Tempfile for cookbook_a apache.conf.erb template",
           :path => "/tmp/cookbook_a_template_default_tempfile")
  end

  def setup_common_files_missing_expectations
    # Files are not in the cache:
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/recipes/default.rb").
      and_return(false)
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/attributes/default.rb").
      and_return(false)

    # Fetch and copy default.rb recipe
    expect(server_api).to receive(:streaming_request).
      with("http://chef.example.com/abc123").
      and_return(cookbook_a_default_recipe_tempfile)
    expect(file_cache).to receive(:move_to).
      with("/tmp/cookbook_a_recipes_default_rb", "cookbooks/cookbook_a/recipes/default.rb")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/recipes/default.rb", false).
      and_return("/file-cache/cookbooks/cookbook_a/recipes/default.rb")

    # Fetch and copy default.rb attribute file
    expect(server_api).to receive(:streaming_request).
      with("http://chef.example.com/abc456").
      and_return(cookbook_a_default_attribute_tempfile)
    expect(file_cache).to receive(:move_to).
      with("/tmp/cookbook_a_attributes_default_rb", "cookbooks/cookbook_a/attributes/default.rb")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/attributes/default.rb", false).
      and_return("/file-cache/cookbooks/cookbook_a/attributes/default.rb")
  end

  def setup_no_lazy_files_and_templates_missing_expectations
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/files/default/megaman.conf").
      and_return(false)
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/templates/default/apache2.conf.erb").
      and_return(false)

    expect(server_api).to receive(:streaming_request).
      with("http://chef.example.com/megaman.conf").
      and_return(cookbook_a_file_default_tempfile)
    expect(file_cache).to receive(:move_to).
      with("/tmp/cookbook_a_file_default_tempfile", "cookbooks/cookbook_a/files/default/megaman.conf")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/files/default/megaman.conf", false).
      and_return("/file-cache/cookbooks/cookbook_a/default/megaman.conf")

    expect(server_api).to receive(:streaming_request).
      with("http://chef.example.com/ffffff").
      and_return(cookbook_a_template_default_tempfile)
    expect(file_cache).to receive(:move_to).
      with("/tmp/cookbook_a_template_default_tempfile", "cookbooks/cookbook_a/templates/default/apache2.conf.erb")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/templates/default/apache2.conf.erb", false).
      and_return("/file-cache/cookbooks/cookbook_a/templates/default/apache2.conf.erb")
  end

  def setup_common_files_chksum_mismatch_expectations
    # Files are in the cache:
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/recipes/default.rb").
      and_return(true)
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/attributes/default.rb").
      and_return(true)

    # Fetch and copy default.rb recipe
    expect(server_api).to receive(:streaming_request).
      with("http://chef.example.com/abc123").
      and_return(cookbook_a_default_recipe_tempfile)
    expect(file_cache).to receive(:move_to).
      with("/tmp/cookbook_a_recipes_default_rb", "cookbooks/cookbook_a/recipes/default.rb")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/recipes/default.rb", false).
      twice.
      and_return("/file-cache/cookbooks/cookbook_a/recipes/default.rb")

    # Current file has fff000, want abc123
    expect(Chef::CookbookVersion).to receive(:checksum_cookbook_file).
      with("/file-cache/cookbooks/cookbook_a/recipes/default.rb").
      and_return("fff000").at_least(:once)

    # Fetch and copy default.rb attribute file
    expect(server_api).to receive(:streaming_request).
      with("http://chef.example.com/abc456").
      and_return(cookbook_a_default_attribute_tempfile)
    expect(file_cache).to receive(:move_to).
      with("/tmp/cookbook_a_attributes_default_rb", "cookbooks/cookbook_a/attributes/default.rb")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/attributes/default.rb", false).
      twice.
      and_return("/file-cache/cookbooks/cookbook_a/attributes/default.rb")

    # Current file has fff000, want abc456
    expect(Chef::CookbookVersion).to receive(:checksum_cookbook_file).
      with("/file-cache/cookbooks/cookbook_a/attributes/default.rb").
      and_return("fff000").at_least(:once)
  end

  def setup_no_lazy_files_and_templates_chksum_mismatch_expectations
    # Files are in the cache:
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/files/default/megaman.conf").
      and_return(true)
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/templates/default/apache2.conf.erb").
      and_return(true)

    # Fetch and copy megaman.conf
    expect(server_api).to receive(:streaming_request).
      with("http://chef.example.com/megaman.conf").
      and_return(cookbook_a_file_default_tempfile)
    expect(file_cache).to receive(:move_to).
      with("/tmp/cookbook_a_file_default_tempfile", "cookbooks/cookbook_a/files/default/megaman.conf")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/files/default/megaman.conf", false).
      twice.
      and_return("/file-cache/cookbooks/cookbook_a/default/megaman.conf")

    # Fetch and copy apache2.conf template
    expect(server_api).to receive(:streaming_request).
      with("http://chef.example.com/ffffff").
      and_return(cookbook_a_template_default_tempfile)
    expect(file_cache).to receive(:move_to).
      with("/tmp/cookbook_a_template_default_tempfile", "cookbooks/cookbook_a/templates/default/apache2.conf.erb")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/templates/default/apache2.conf.erb", false).
      twice.
      and_return("/file-cache/cookbooks/cookbook_a/templates/default/apache2.conf.erb")

    # Current file has fff000
    expect(Chef::CookbookVersion).to receive(:checksum_cookbook_file).
      with("/file-cache/cookbooks/cookbook_a/default/megaman.conf").
      and_return("fff000")

    # Current file has fff000
    expect(Chef::CookbookVersion).to receive(:checksum_cookbook_file).
      with("/file-cache/cookbooks/cookbook_a/templates/default/apache2.conf.erb").
      and_return("fff000")
  end

  def setup_common_files_present_expectations
    # Files are in the cache:
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/recipes/default.rb").
      and_return(true)
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/attributes/default.rb").
      and_return(true)

    # Current file has abc123, want abc123
    expect(Chef::CookbookVersion).to receive(:checksum_cookbook_file).
      with("/file-cache/cookbooks/cookbook_a/recipes/default.rb").
      and_return("abc123").at_least(:once)

    # Current file has abc456, want abc456
    expect(Chef::CookbookVersion).to receive(:checksum_cookbook_file).
      with("/file-cache/cookbooks/cookbook_a/attributes/default.rb").
      and_return("abc456").at_least(:once)

    # :load called twice
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/recipes/default.rb", false).
      twice.
      and_return("/file-cache/cookbooks/cookbook_a/recipes/default.rb")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/attributes/default.rb", false).
      twice.
      and_return("/file-cache/cookbooks/cookbook_a/attributes/default.rb")
  end

  def setup_no_lazy_files_and_templates_present_expectations
    # Files are in the cache:
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/files/default/megaman.conf").
      and_return(true)
    expect(file_cache).to receive(:has_key?).
      with("cookbooks/cookbook_a/templates/default/apache2.conf.erb").
      and_return(true)

    # Current file has abc124, want abc124
    expect(Chef::CookbookVersion).to receive(:checksum_cookbook_file).
      with("/file-cache/cookbooks/cookbook_a/default/megaman.conf").
      and_return("abc124")

    # Current file has abc125, want abc125
    expect(Chef::CookbookVersion).to receive(:checksum_cookbook_file).
      with("/file-cache/cookbooks/cookbook_a/templates/default/apache2.conf.erb").
      and_return("abc125")

    # :load called twice
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/files/default/megaman.conf", false).
      twice.
      and_return("/file-cache/cookbooks/cookbook_a/default/megaman.conf")
    expect(file_cache).to receive(:load).
      with("cookbooks/cookbook_a/templates/default/apache2.conf.erb", false).
      twice.
      and_return("/file-cache/cookbooks/cookbook_a/templates/default/apache2.conf.erb")
  end

  describe "#server_api" do
    it "sets keepalive to true" do
      expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url], keepalives: true)
      synchronizer.server_api
    end
  end

  describe "when syncing cookbooks with the server" do
    let(:server_api) { double("Chef::ServerAPI (mock)") }

    let(:file_cache) { double("Chef::FileCache (mock)") }

    before do
      # Would rather not stub out methods on the test subject, but setting up
      # the state is a PITA and tests for this behavior are above.
      allow(synchronizer).to receive(:clear_obsoleted_cookbooks)
      allow(synchronizer).to receive(:server_api).and_return(server_api)
      allow(synchronizer).to receive(:cache).and_return(file_cache)
    end

    context "when the cache does not contain the desired files" do
      before do
        setup_common_files_missing_expectations
      end

      context "Chef::Config[:no_lazy_load] is false" do
        let(:no_lazy_load) { false }

        it "fetches eagerly loaded files" do
          synchronizer.sync_cookbooks
        end

        it "does not fetch templates or cookbook files" do
          # Implicitly tested in previous test; this test is just for behavior specification.
          expect(server_api).not_to receive(:streaming_request).
            with("http://chef.example.com/ffffff")

          synchronizer.sync_cookbooks
        end
      end

      context "Chef::Config[:no_lazy_load] is true" do
        let(:no_lazy_load) { true }

        before do
          setup_no_lazy_files_and_templates_missing_expectations
        end

        it "fetches templates and cookbook files" do
          synchronizer.sync_cookbooks
        end
      end
    end

    context "when the cache contains outdated files" do
      before do
        setup_common_files_chksum_mismatch_expectations
      end

      context "Chef::Config[:no_lazy_load] is true" do
        let(:no_lazy_load) { true }

        before do
          setup_no_lazy_files_and_templates_chksum_mismatch_expectations
        end

        it "updates the outdated files" do
          synchronizer.sync_cookbooks
        end
      end

      context "Chef::Config[:no_lazy_load] is false" do
        let(:no_lazy_load) { false }

        it "updates the outdated files" do
          synchronizer.sync_cookbooks
        end
      end
    end

    context "when the cache is up to date" do
      before do
        setup_common_files_present_expectations
      end

      context "Chef::Config[:no_lazy_load] is true" do
        let(:no_lazy_load) { true }

        before do
          setup_no_lazy_files_and_templates_present_expectations
        end

        it "does not update files" do
          expect(file_cache).not_to receive(:move_to)
          expect(server_api).not_to receive(:streaming_request)
          synchronizer.sync_cookbooks
        end
      end

      context "Chef::Config[:no_lazy_load] is false" do
        let(:no_lazy_load) { false }

        it "does not update files" do
          expect(file_cache).not_to receive(:move_to)
          expect(server_api).not_to receive(:streaming_request)
          synchronizer.sync_cookbooks
        end
      end
    end
  end
end
