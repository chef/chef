module CookbookHelper
  
  require 'aws/s3'

  def put_in_couchdb_and_s3(cookbook_name, file, revision)
    # TODO: set inital state of cookbook to something like 'pre-upload'
    cookbook = Cookbook.on(database_from_orgname(params[:organization_id])).new(:display_name => cookbook_name, :revision => revision)
    save cookbook
    
    id = cookbook['_id']
    Merb.logger.debug "Creating cookbook with id = #{id}"
    
    stream_to_s3(params[:file][:tempfile], id)
    
    # TODO: if upload successful, set cookbook state to something like 'active'
  end
  
  def validate_tarball(filepath, cookbook_name)
    raise "(try creating with 'tar czf cookbook.tgz cookbook/')" unless system("tar", "tzf", filepath)
    
    # TODO: modify/implement tests and uncomment the next lines

#     required_entry_roots = [cookbook_name]
#     allowed_entry_roots = [cookbook_name, "ignore"]
    
#     entry_roots = `tar tzf #{filepath}`.split("\n").map{|e|e.split('/').first}.uniq
    
#     illegal_roots = entry_roots - allowed_entry_roots
#     raise "tarball root may only contain #{allowed_entry_roots.join(', ')}" unless illegal_roots.empty?
    
#     missing_required_roots = required_entry_roots - entry_roots
#     raise "tarball root must contain #{required_entry_roots.join(', ')}" unless missing_required_roots.empty?
  end

  def get_all_cookbook_entries(cookbook_name)
    rows = Cookbook.on(database_from_orgname(params[:organization_id])).by_display_name(:key => cookbook_name, :include_docs => true)
    Merb.logger.debug "Cookbook has the following entries: #{rows.inspect}"
    rows
  end
  
  def cookbook_id(cookbook_name)
    rows = get_all_cookbook_entries(cookbook_name)
    return nil if rows.empty?
    most_recent_record = rows.sort_by{|row| row['revision'].to_i}.last
    Merb.logger.debug "Selected #{most_recent_record.inspect}"
    [most_recent_record['_id'], most_recent_record['revision']]
  end
  
    # TODO: should we do this once at start-up and test the connection before establishing it?
  def establish_connection
    AWS::S3::Base.establish_connection!(
                                        :access_key_id     => Merb::Config[:aws_secret_access_key_id],
                                        :secret_access_key => Merb::Config[:aws_secret_access_key]
                                        )
  end

  def stream_to_s3(path, object_id)
    establish_connection
    AWS::S3::S3Object.store("#{object_id}.tgz", open(path), Merb::Config[:aws_cookbook_tarball_s3_bucket])
  end

  def stream_from_s3(cookbook_name, id)
    establish_connection
    # TODO: if the cookbook is large and the user has a slow connection, will this cause the process's memory to bloat or will it just read from S3 slowly?
    stream_file do |response|
      AWS::S3::S3Object.stream("#{id}.tgz", Merb::Config[:aws_cookbook_tarball_s3_bucket]) do |chunk|
        response.write chunk
      end
    end
  end

  # TODO: the following methods were heisted from opscode-account. if this is how we want to do it, then do some hoisting
  
  def save(object)
    if object.valid?
      object.save
    else
      raise BadRequest, object.errors.full_messages
    end
  end
  
  def orgname_to_dbname(orgname)
    "chef_#{orgname}"
  end
  
  def database_from_orgname(orgname)
    CouchRest::Database.new(CouchRest::Server.new,orgname_to_dbname(orgname))
  end

end
