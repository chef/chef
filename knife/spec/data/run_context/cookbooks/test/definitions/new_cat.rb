define :new_cat, :is_pretty => true do
  cat "#{params[:name]}" do
     pretty_kitty params[:is_pretty]
  end
end
