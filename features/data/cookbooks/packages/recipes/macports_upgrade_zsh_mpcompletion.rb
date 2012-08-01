package "zsh" do
  action :remove
  variants "+mp_completion"
end

package "zsh" do
  action :upgrade
  variants "+mp_completion"
end
