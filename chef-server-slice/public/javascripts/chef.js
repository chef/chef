//
// Author:: Adam Jacob (<adam@opscode.com>)
// Author:: AJ Christensen (<aj@junglist.gen.nz>)
// Copyright:: Copyright (c) 2008 Opscode, Inc.
// License:: Apache License, Version 2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

$(document).ready(function(){
  // livequery hidden form for link_to ajax magic
  $('a[method]').livequery(function(){
    var message = $(this).attr('confirm');
    var method  = $(this).attr('method');
    
    if (!method && !message) return;
    
    $(this).click(function(event){
      if (message && !confirm(message)) {
        event.preventDefault();
        return;
      }
      
      if (method == 'post' || method == 'put' || method == 'delete') {
        event.preventDefault();
        var form = $("<form/>").attr('method', 'post').attr('action', this.href).attr('style', 'display: none');
        if (method != "post") {
          form.append($('<input type="hidden" name="_method"/>').attr('value', method));
        }
        form.insertAfter(this).submit();
      }
    });
  });
  
  $("dd:has(dl)").livequery(function(){
    $(this).hide().prev("dt").addClass("collapsed");
  });
  $("dd:not(:has(dl))").livequery(function(){
    $(this).addClass("inline").prev().addClass("inline");
  });
  $("dt.collapsed").livequery(function(){
    $(this).click(function() {
      $(this).toggleClass("collapsed").next().toggle();
    });
  });
  
  // editable table for the node show view
  $(".edit_area").editable(location.href + ".json", { 
    target : location.href,
    method : "PUT",
    submit : "Save",
    cancel : "Cancel",
    indicator : "Saving..",
    loadurl : location.href,
    tooltip : "Click to edit",
    type  : "textarea",
    event     : "dblclick",
    height : 300
  });
  

  //alert("blah" + $('#json_tree_source').text());
  //var json = $('#json_tree_source').text();
  //$('#attribute_tree_view').append(TreeView($('#json_tree_source').text()));
  
  // accordion for the cookbooks show view
	$('.accordion .head').click(function() {
		$(this).next().toggle('slow');
		return false;
	}).next().hide();
	
	// global facebox callback
	$('a[rel*=facebox]').facebox();
	
	/*
  JSONEditor.prototype.ADD_IMG = '/images/add.png';
  JSONEditor.prototype.DELETE_IMG = '/images/delete.png';
  var attrib_editor = new JSONEditor($("#attrib_json_edit"), 400, 300);
  attrib_editor.doTruncation(true);
  attrib_editor.showFunctionButtons();
  
  var recipe_editor = new JSONEditor($("#recipe_json_edit"), 400, 300);
  recipe_editor.doTruncation(true);
  recipe_editor.showFunctionButtons();
  */
});