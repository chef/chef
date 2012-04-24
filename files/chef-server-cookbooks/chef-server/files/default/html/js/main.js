//ie6 menu hover
function initMenu()
{
var _nav = document.getElementById("nav");
if (_nav) {
   var nodes = _nav.getElementsByTagName("li");
   for (var i=0; i<nodes.length; i++) {
      nodes[i].onmouseover = function()
      {
         if (this.className.indexOf('hover') == -1)
            this.className += " hover";
      }
      nodes[i].onmouseout = function()
      {
         this.className = this.className.replace(" hover", "");
      }
   }
}
}
if (document.all && !window.opera) attachEvent("onload", initMenu);


