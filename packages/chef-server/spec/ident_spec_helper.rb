module IdentSpecHelper
  def valid_ident_hash
    { :login                  => "daniel",
      :email                  => "daniel@example.com",
      :password               => "sekret",
      :password_confirmation  => "sekret"}
  end
end