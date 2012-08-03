$(document).ready(function() {
  // add version constraints, sorted by cookbook name
  var cookbook, versions, constraints = [], i = 0, max, row;
  if (document.getElementById('edit') != null) {
    versions = cookbook_versions();
    for (cookbook in versions) {
      constraints.push([cookbook, versions[cookbook]["op"],
                     versions[cookbook]["version"]]);
    }
    constraints.sort();
    for (i = constraints.length - 1; i >= 0; i--) {
      row = constraints[i];
      addTableRow(row[0], row[1], row[2]);
    }
  }
})

function jQuerySuggest(timestamp){
  $(".ac_results").remove(); // FIXME issue w/ jquery suggest
  var cb_name = retrieveCbName(timestamp);
  populateVersionBoxContent(timestamp, cb_name);
  $("#cookbook_version_" + timestamp)[0].value = "0.0.0";
}

function populateVersionBoxContent(timestamp, cb_name){
  // Ignore environments when editing the environments constraints
  $.getJSON('/cookbooks/'+cb_name+'?num_versions=all&ignore_environments=true',
            function(result){
              var versions = $.map(result[cb_name],
                                   function(item, i) {
                                     return item["version"];
                                   });
              jQuery('#cookbook_version_' + timestamp).suggest(versions);
            });
}

function clearVersionBox(box, timestamp){
  populateVersionBoxContent(timestamp, retrieveCbName(timestamp));
  $('#invalid_version_error_' + timestamp).remove();
}

function validVersion(version) {
  var xyz_match = version.match(/^\d+\.\d+\.\d+$/);
  var xy_match = version.match(/^\d+\.\d+$/);
  return (xyz_match || xy_match);
}

function do_validateVersionBoxValue(box, timestamp) {
  var msg_class = 'invalid_version_error';
  var msg_id = 'invalid_version_error_' + timestamp;
  if (!validVersion(box.value)) {
    if (box.value.length != 0 && $('.' + msg_class).length == 0) {
      var error_msg = $('<div/>')
        .addClass(msg_class)
        .attr('id', msg_id).text("Version must be x.y.z or x.y");
      $(box).parent().append(error_msg);
    }
    if (box.value.length == 0) {
      box.value = "0.0.0";
    }
    return false;
  }
  return true;
}

function validateVersionBoxValue(box, timestamp) {
  // a short delay prevents validation from firing
  // when user clicks on one of the suggestions.
  setTimeout(function() {
    return do_validateVersionBoxValue(box, timestamp);
  }, 100);
}

function appendOperatorsOptions(default_operator, obj) {
  var ops = ["~>", ">=", ">", "=", "<", "<="];
  for (i in ops) {
    var op = ops[i]
    var option = $('<option/>').attr("value", op).text(op);
    if (default_operator == op) {
      option.attr("selected", "true");
    }
    obj.append(option);
  }
}

function retrieveCbName(timestamp) {
  var cb_name_item = $('#cookbook_name_' + timestamp)[0];
  if (cb_name_item && cb_name_item.value) {
    return cb_name_item.value;
  }
  return "";
}

function constraint_exists(cookbook) {
  var cookbooks = $('.hidden_cookbook_name').map(
    function(i, x) { return x.value });
  return $.inArray(cookbook, cookbooks) > -1;
}

function validateUniqueConstraint(cookbook) {
  var msg_class = 'invalid_version_error';
  var msg_id = 'duplicate_cookbook_error';
  if (constraint_exists(cookbook)) {
    var error_msg = $('<div/>')
      .addClass(msg_class)
      .attr('id', msg_id).text("constraint already exists for " + cookbook);
    $('#cookbook_name_0000').parent().append(error_msg);
    return false;
  }
  return true;
}

function clearCookbookError() {
  $('#duplicate_cookbook_error').remove();
}

function validTableRow(default_cookbook, default_version) {
  if (default_cookbook == "") return false;
  if (!validateUniqueConstraint(default_cookbook)) return false;
  if (!validVersion(default_version)) return false;
  return true;
}

function addTableRow(default_cookbook, default_operator, default_version){
  if (!validTableRow(default_cookbook, default_version)) return;
  var timestamp = new Date().getTime();
  var row = $('<tr/>');
  var td_name = make_td_name(default_cookbook, timestamp);
  var td_op = make_td_op(default_operator, timestamp);
  var td_version = make_td_version(default_version, timestamp);
  var td_rm = make_td_remove(row);
  row.append(td_name).append(td_op).append(td_version).append(td_rm);
  $("#cbVerAddRow").parent().after(row);
  validateVersionBoxValue(document.getElementById("cookbook_version_" + timestamp));
  clearConstraintEditor();
}

function clearConstraintEditor() {
  $("#cookbook_name_0000")[0].value = "";
  $("#cookbook_operator_selector")[0].selectedIndex = 0;
  $("#cookbook_version_0000")[0].value = "0.0.0";
}

function addTableRow0000() {
  var cookbook = $("#cookbook_name_0000")[0].value;
  var operator = $("#cookbook_operator_selector")[0].value;
  var version = $("#cookbook_version_0000")[0].value;
  addTableRow(cookbook, operator, version);
}

function make_td_name(default_cookbook, timestamp) {
  var td_name = $('<td/>').text(default_cookbook)
  var name_hidden = $('<input>')
    .addClass("hidden_cookbook_name")
    .attr("id", "cookbook_name_" + timestamp)
    .attr("type", "hidden")
    .attr("name", "cookbook_name_" + timestamp)
    .attr("value", default_cookbook);
  td_name.append(name_hidden);
  return td_name;
}

function make_td_version(default_version, timestamp) {
  var version_box = $('<input>')
    .addClass("text")
    .attr("name", "cookbook_version_" + timestamp)
    .attr("id", "cookbook_version_" + timestamp)
    .attr("type", "text")
    .attr("value", default_version)
    .focus(function() { clearVersionBox(this, timestamp) })
    .blur(function() { validateVersionBoxValue(this, timestamp) })
  return $('<td/>').append(version_box);
}

function make_td_op(default_operator, timestamp) {
  var select_op = $('<select/>').attr('name', "operator_" + timestamp);
  appendOperatorsOptions(default_operator, select_op);
  return $('<td/>').append(select_op);
}

function make_td_remove(row) {
  return $('<td/>').append($('<a/>')
                           .text("remove")
                           .attr("href", "javascript:void(0)")
                           .click(function() { row.remove() }));
}

function removeTableRow(row){
    row.remove();
}
  
