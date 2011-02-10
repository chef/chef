// function cookbook_versions_show_more() {
//   var cookbook = this.attributes["data"].textContent;
//   // do AJAX here and get back something like this:
//   var extra_versions = [{version : "0.0.1", url : "/cookbooks/" + cookbook + "/0.0.1/"}, 
//                         {version : "0.0.3", url : "/cookbooks/" + cookbook + "/0.0.3"}];

//   // NOTE: we're going to try not caching and will repeat ajax calls
//   // on repeated click because the data could have changed on the
//   // server.  We can revisit if this feels wrong for real-world UX
//   var version_list = $("#" + cookbook + "_versions");
//   var tmp_list = $('<ol/>');
//   $.each(extra_versions, function(i, x) {
//     var link = $('<a/>').attr("href", x.url).text(x.version);
//     var item = $('<li/>').append(link);
//     tmp_list.append(item);
//   });
//   version_list.html(tmp_list.html());
//   $(this).unbind("click");
//   $(this).click(cookbook_versions_show_less);
//   return false;
// }
function cookbook_versions_show_more() {
  var cookbook = $(this).attr("data");
  var version_list = $("#" + cookbook + "_versions");
  if (version_list.children().length == 1) {
    return;
  }
  version_list.children('.other_version').show();
  $("#" + cookbook + "_show_all").show();
  $(this).unbind("click");
  $(this).html("&#8211;"); // FIXME: set css class here, to determine icon image
  $(this).click(cookbook_versions_show_less);
}

function cookbook_versions_show_less() {
  console.log($(this));
  var cookbook = $(this).attr("data");
  var version_list = $("#" + cookbook + "_versions");
  version_list.children('.other_version').hide();
  version_list.children('.all_version').hide();
  $("#" + cookbook + "_show_all").hide();
  $(this).unbind("click");
  $(this).text("+"); // FIXME: set css class here, to determine icon image
  $(this).click(cookbook_versions_show_more);
}

function cookbook_versions_show_all() {
  var self = $(this);
  var cookbook = self.attr("data");
  var version_list = $("#" + cookbook + "_versions");
  var all_versions = version_list.children('.all_version');
  if (all_versions.length > 0) {
    all_versions.show();
    self.hide();
    return;
  }
  var callback = function(data, textStatus, jqXHR) {
    var all_versions = $('<ol/>');
    console.log("got " + data[cookbook].length + " items for " + cookbook);
    for (var i in data[cookbook]) {
      var v = data[cookbook][i];
      klass = "all_version";
      if (i == 0) {
        klass = "latest_version";
      }
      else if (i < 5) {
        klass = "other_version";
      }
      var link = $('<a/>').attr("href", v.url).text(v.version);
      var item = $('<li/>').addClass(klass).append(link);
      all_versions.append(item);
    }
    version_list.html(all_versions.html());
    self.hide();
  }
  $.ajax({
    url : "/cookbooks/" + cookbook + "?num_versions=all",
    dataType: "json",
    success : callback,
    error : function(jqXHR, textStatus, errorThrown) {
      // FIXME
      console.log(textStatus);
    }
  })
}

function fetch_all_versions0(cookbook) {
  $.ajax({
    url : "/cookbooks/" + cookbook,
    dataType: "json",
    success : function(data, textStatus, jqXHR) {
      console.log(data);
    },
    error : function(jqXHR, textStatus, errorThrown) {
      console.log(textStatus);
    }
    
  })
}

$(document).ready(function() {
  $('td.show_more a').click(cookbook_versions_show_more);
  $('td.show_more a').each(cookbook_versions_show_less);
  $('a.show_all').click(cookbook_versions_show_all);
})

