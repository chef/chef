class Chef
  class Solr
    VERSION = '10.12.0.rc.1'

    # Solr Schema. Used to detect incompatibilities between installed solr and
    # chef-solr versions.
    SCHEMA_NAME = "chef"
    SCHEMA_VERSION = '1.2'

  end
end
