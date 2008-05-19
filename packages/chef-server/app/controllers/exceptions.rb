class Exceptions < Application
  
  provides :html, :json
  
  # handle NotFound exceptions (404)
  def not_found
    display params
  end

  # handle NotAcceptable exceptions (406)
  def not_acceptable
    display params
  end
  
  # handle BadRequest exceptions (400)
  def bad_request
    display params
  end

end