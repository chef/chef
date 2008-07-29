class Cookbooks < Application
  
  provides :html, :json
  
  def index
    @cl = Chef::CookbookLoader.new
    display @cl
  end

  def show
    @cl = Chef::CookbookLoader.new
    @cookbook = @cl[params[:id]]
    raise NotFound unless @cookbook
    display @cookbook
  end

  def attribute_files
    cl = Chef::CookbookLoader.new
    @attribute_files = Array.new
    cl.each do |cookbook|
      cookbook.attribute_files.each do |af|
        @attribute_files << { 
          :cookbook => cookbook.name, 
          :name => File.basename(af), 
          :path => af,
          :contents => File.read(af) 
        }
      end
    end
    display @attribute_files
  end
  
end
