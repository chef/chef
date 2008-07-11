class Search < Application
  
  provides :html, :json
    
  def index
    @s = Chef::Search.new
    @search_indexes = @s.list_indexes
    display @search_indexes
  end

  def show
    @s = Chef::Search.new
    @results = nil
    if params[:q]
      @results = @s.search(params[:id], params[:q] == "" ? "?*" : params[:q])
    else
      @results = @s.search(params[:id], "?*")
    end
    # Boy, this should move to the search function
    if params[:a]
      attributes = params[:a].split(",").collect { |a| a.to_sym }
      unless attributes.length == 0
        @results = @results.collect do |r|
          nr = Hash.new
          nr[:index_name] = r[:index_name]
          nr[:id] = r[:id]
          attributes.each do |attrib|
            if r.has_key?(attrib)
              nr[attrib] = r[attrib]
            end
          end
          nr
        end
      end
    end
    display @results
  end

  def destroy
    @s = Chef::Search.new
    @entries = @s.search(params[:id], "?*")
    @entries.each do |entry|
      Chef::Queue.send_msg(:queue, :remove, entry)
    end
    @status = 202
    if content_type == :html
      redirect url(:search)
    else
      display @entries
    end
  end
  
end
