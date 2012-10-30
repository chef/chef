define :new_dog, :is_cute => true do
  dog "#{params[:name]}" do
    cute params[:is_cute]
  end
end

define :new_badger do
  badger "#{params[:name]}"
end
