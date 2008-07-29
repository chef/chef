class CookbookTemplates < Application
  
  provides :html, :json
  
  def load_cookbook(with_content=false)
    @cl = Chef::CookbookLoader.new
    @cookbook = @cl[params[:cookbook_id]]
    raise NotFound unless @cookbook
    @templates = Hash.new
    @cookbook.template_files.each do |tf|
      @templates[File.basename(tf)] = {
        :file => tf,
      }
      @templates[File.basename(tf)][:contents] = File.read(tf) if with_content
    end
  end
  
  def index
    load_cookbook(false)
    display @templates
  end

  def show
    load_cookbook(true)
    @template = @templates[params[:id]]
    display @template
  end
  
end
