class SearchEntries < Application
  
  provides :html, :json
    
  def index
    @s = Chef::Search.new
    @entries = @s.search(params[:search_id], "?*")
    display @entries
  end

  def show
    @s = Chef::Search.new
    @entry = @s.search(params[:search_id], "id:'#{params[:search_id]}_#{params[:id]}'").first
    display @entry
  end
  
  def create
    @to_index = params
    @to_index.delete(:controller)
    @to_index["index_name"] = params[:search_id]
    @to_index["id"] = "#{params[:search_id]}_#{params[:id]}"
    @to_index.delete(:search_id)
    Chef::Queue.send_msg(:queue, :index, @to_index)
    if content_type == :html
      redirect url(:search)
    else
      @status = 202
      display @to_index
    end
  end
  
  def update
    create
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
