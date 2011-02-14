function cookbook_versions_show_more() {
  var cookbook = $(this).attr("data");
  var version_list = $("#" + cookbook + "_versions");
  if (version_list.children().length == 1) {
    return;
  }
  version_list.children('.other_version').show();
  $("#" + cookbook + "_show_all").show();
  $(this).unbind("click");
  // en-dash == &#8211;
  $(this).html("&#8211;").attr("title", "hide other versions of " + cookbook);
  $(this).click(cookbook_versions_show_less);
}

function cookbook_versions_show_less() {
  var cookbook = $(this).attr("data");
  var version_list = $("#" + cookbook + "_versions");
  version_list.children('.other_version').hide();
  version_list.children('.all_version').hide();
  $("#" + cookbook + "_show_all").hide();
  $(this).unbind("click");
  $(this).text("+").attr("title", "show other versions of " + cookbook);
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
  var spinner = $('<img/>')
    .attr("src", "/images/indicator.gif")
    .attr("id", "show_all_versions_spinner");
  self.after(spinner);
  self.hide();
  var callback = function(data, textStatus, jqXHR) {
    var all_versions = $('<ol/>');
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
    spinner.remove();
  }
  $.ajax({
    url : "/cookbooks/" + cookbook + "?num_versions=all",
    dataType: "json",
    success : callback,
    error : function(jqXHR, textStatus, errorThrown) {
      spinner.remove();
      self.show();
    }
  })
}

$(document).ready(function() {
  $('td.show_more a').click(cookbook_versions_show_more);
  $('td.show_more a').each(cookbook_versions_show_less);
  $('a.show_all').click(cookbook_versions_show_all);
})

