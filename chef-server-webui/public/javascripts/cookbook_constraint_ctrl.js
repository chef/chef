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
  error_message = document.getElementById('inline_error_message_' + timestamp);
  if (error_message != null)
    $(error_message).remove();
}

function validateVersionBoxValue(box, timestamp){
  setTimeout(function() {
  if (box.value.match(/^[0-9]+\.[0-9]+\.[0-9]+$/) == null){
    if (box.value.length != 0 && document.getElementById('inline_error_message_' + timestamp) == null)
      $(box).parent().append('<span class="inline_error_message" id="inline_error_message_' + timestamp + '" >Invalid version format. The version should be in the format of x.y.z.</span>');
      if (box.value.length==0)
        box.value = "0.0.0";
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
