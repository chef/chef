class Chef
  class Solr
    VERSION = '10.18.0.rc.2'

    # Solr Schema. Used to detect incompatibilities between installed solr and
    # chef-solr versions.
    SCHEMA_NAME = "chef"
    SCHEMA_VERSION = '1.2'

  end
end
