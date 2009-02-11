define :gnome do
  params[:underpants].each do |undies|
    execute "echo gnome #{undies}" do
      command "echo 'gnome has underpants #{undies}'"
    end
  end
end