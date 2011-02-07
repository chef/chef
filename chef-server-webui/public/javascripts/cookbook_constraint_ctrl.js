function jQuerySuggest(timestamp){
  var cb_name = retrieveCbName(timestamp);
  populateVersionBoxContent(timestamp, cb_name);
  document.getElementById("cookbook_version_" + timestamp).value = "0.0.0";
}

function populateVersionBoxContent(timestamp, cb_name){
  $.getJSON('/cookbooks/'+cb_name, function(result){
                                     jQuery('#cookbook_version_'+timestamp).suggest(result[cb_name]);
                                   });
}

function clearVersionBox(box, timestamp){
  populateVersionBoxContent(timestamp, retrieveCbName(timestamp));
  //if (box.value == "0.0.0"){box.value = "";}
  error_message = document.getElementById('inline_error_message_' + timestamp);
  if (error_message != null)
    $(error_message).remove();
}

function validateVersionBoxValue(box, timestamp){
  if (box.value.match(/\d+\.\d+\.\d+$/) == null){
    if (box.value.length != 0 && document.getElementById('inline_error_message_' + timestamp) == null)
      $(box).parent().append('<span class="inline_error_message" id="inline_error_message_' + timestamp + '" >Invalid version format. The version should be in the format of 0.0.0.</span>');
      if (box.value.length==0)
        box.value = "0.0.0";
  }
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