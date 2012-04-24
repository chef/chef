$(document).ready(function(){
  
  var btns_flag = 2;
  
  $("#btn-slide").hover(
    function()
    {
      if (btns_flag >= 2)
      {
        $(".login-form").slideToggle(100);
        btns_flag = 0;
      }
      },
    
    function ()
    {
      btns_flag++;
    }
  );
    
    $("#close").click(
    function()
    {
            $(".login-form").slideToggle(100);
        }
  );
    
});



	
	
	