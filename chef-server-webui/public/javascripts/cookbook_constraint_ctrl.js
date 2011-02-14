function jQuerySuggest(timestamp){
  var cb_name = retrieveCbName(timestamp);
  populateVersionBoxContent(timestamp, cb_name);
  document.getElementById("cookbook_version_" + timestamp).value = "0.0.0";
}

function populateVersionBoxContent(timestamp, cb_name){
  // Ignore environments when editing the environments constraints
  $.getJSON('/cookbooks/'+cb_name+'?num_versions=all&ignore_environments=true',
            function(result){
              console.log("result");
              console.log(result);
              var versions = $.map(result[cb_name],
                                   function(item, i) {
                                     return item["version"];
                                   });
              jQuery('#cookbook_version_'+timestamp).suggest(versions);
            });
}

function clearVersionBox(box, timestamp){
  populateVersionBoxContent(timestamp, retrieveCbName(timestamp));
  $('#invalid_version_error_' + timestamp).remove();
}

function validateVersionBoxValue(box, timestamp) {  
  setTimeout(function() {
    var msg_class = 'invalid_version_error';
    var msg_id = 'invalid_version_error_' + timestamp;
    var xyz_match = box.value.match(/^\d+\.\d+\.\d+$/);
    var xy_match = box.value.match(/^\d+\.\d+$/);
    if (!xyz_match && !xy_match) {
      if (box.value.length != 0 && $('.' + msg_class).length == 0) {
        var error_msg = $('<div/>')
          .addClass(msg_class)
          .attr('id', msg_id).text("Version must be x.y.z or x.y");
        $(box).parent().append(error_msg);
      }
      if (box.value.length == 0) {
        box.value = "0.0.0";
      }
    }
  }, 100);
}

function buildCookbookList(cookbook_names, default_cookbook){
  if (default_cookbook != null && $.inArray(default_cookbook, cookbook_names) < 0){
    cookbook_names.push(default_cookbook);
  }
  var result = '<option value=""></option>';
  for(i=0; i<cookbook_names.length; i++){
    result += '<option value=' + '"' + cookbook_names[i] + '" ';
    if (cookbook_names[i] == default_cookbook)
      result += 'selected=true>' + cookbook_names[i] + '</option>';
    else
      result += '>' + cookbook_names[i] + '</option>';
  }
  return result;
}

function buildOperatorList(default_operator){
  return '<option value="&gt;="' +  (default_operator == ">=" ? "selected=true" : "") + '>&gt;=</option>'
       + '<option value="&gt;"' +  (default_operator == ">" ? "selected=true" : "" )+ '>&gt;</option>'
       + '<option value="="' + (default_operator == "=" ? "selected=true" : "") +'>=</option>'
       + '<option value="&lt;"' + (default_operator == "<" ? "selected=true" : "") + '>&lt;</option>'
       + '<option value="&lt;="' + (default_operator == "<=" ? "selected=true" : "") + '>&lt;=</option>'
       + '<option value="~&gt;"' + (default_operator == "~>" ? "selected=true" : "") + '>~&gt;</option>';
}

function retrieveCbName(timestamp){
  var select_box = document.getElementById("cookbook_name_" + timestamp);
  return select_box.options[select_box.selectedIndex].value;
}

function addTableRow(default_cookbook, default_operator, default_version){
    var cookbook_names_string = document.getElementById('cbVerPickerTable').getAttribute('data-cookbook_names');
    var cookbook_names = cookbook_names_string.substring(2, cookbook_names_string.length-2).split('","');
    if (cookbook_names[0] == "[]")
      cookbook_names = [];
    var timestamp = new Date().getTime();
    var row = '<tr id=' + '"' + timestamp + '"><td>' + '<select size="1" name="cookbook_name_' + timestamp + '" ' + 'id="cookbook_name_' + timestamp + '" class="cookbook_version_constraints_cb_name" onchange="jQuerySuggest(' + timestamp + ')"'+'>'
            + buildCookbookList(cookbook_names, default_cookbook) + '</select>'
            + '</td>'
            + '<td><select name="operator_' + timestamp + '">' + buildOperatorList(default_operator) + '</select></td>'
            + '<td><input class="text" name="cookbook_version_' + timestamp +'" ' + 'id="cookbook_version_' + timestamp + '" ' + 'type="text" onfocus="clearVersionBox(this,' + timestamp + ')" onblur="validateVersionBoxValue(this,' + timestamp + ')" value="' + default_version + '"></td>'
            + '<td><a href="javascript::void(0)" onclick="removeTableRow($(this).parent().parent())">Remove</a></td>'
            + '</tr>';
    $("#cbVerPickerTable tbody").append(row);
    validateVersionBoxValue(document.getElementById("cookbook_version_" + timestamp));
}

function removeTableRow(row){
    row.remove();
}
