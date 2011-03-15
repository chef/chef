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

  $('form#edit_role, form#create_role').submit(function(event) {
    var form = $(this);
    var to_role = $('ul#for_role').sortable('toArray');
    if (form.attr('id') === 'edit_role') {
      form.append('<input type="hidden" name="_method" value="put">');
    }
    form.append($('input#role_name')).css('display', 'none');
    form.append($('textarea#role_description')).css('display', 'none');
    form.append('<input type="hidden" id="default_attributes" name="default_attributes"/>');
    $('input#default_attributes').attr('value', BCJTEP.save('json["defaults"]'));
    form.append('<input type="hidden" id="override_attributes" name="override_attributes"/>');
    $('input#override_attributes').attr('value', BCJTEP.save('json["overrides"]'));
    jQuery.each(to_role, function(i, field) {
      form.append('<input type="hidden" name="for_role[]" value="' + field + '"/>');
    });
  });

  $('form#edit_node, form#create_node').submit(function(event) {
    var form = $(this);
    var to_node = $('ul#for_node').sortable('toArray');
    if (form.attr('id') === 'edit_node') {
      form.append('<input type="hidden" name="_method" value="put">');
    }
    form.append($('input#node_name')).css('display', 'none');
    form.append('<input type="hidden" id="attributes" name="attributes"/>');
    $('input#attributes').attr('value', BCJTEP.save());
    jQuery.each(to_node, function(i, field) {
      form.append('<input type="hidden" name="for_node[]" value="' + field + '"/>');
    });
  });

  $('form#edit_databag_item, form#create_databag_item').submit(function(event) {
    var form = $(this);
    if (form.attr('id') === 'edit_databag_item') {
      form.append('<input type="hidden" name="_method" value="put">');
    }
    form.append('<input type="hidden" id="json_data" name="json_data"/>');
    form.append($('input#json_data').attr('value', BCJTEP.save()));
  });

	$('form#edit_databag, form#create_databag').submit(function(event) {
    var form = $(this);
    if (form.attr('id') === 'edit_databag') {
      form.append('<input type="hidden" name="_method" value="put">');
    }
    form.append($('input#databag_name')).css('display', 'none');
  });

  $('form#edit_client, form#create_client').submit(function(event) {
    var form = $(this);
    if (form.attr('id') === 'edit_client') {
      form.append('<input type="hidden" name="_method" value="put">');
    }
    form.append($('input#client_name')).css('display', 'none');
    form.append($('input#client_admin')).css('display', 'none');
    form.append($('input#client_private_key')).css('display', 'none');
    form.append($('input#regen_private_key')).css('display', 'none');

  });


  $('form#edit_user, form#login').submit(function(event) {
    var form = $(this);
    if (form.attr('id') === 'edit_user') {
      form.append('<input type="hidden" name="_method" value="put">');
    	form.append($('input#user_new_password')).css('display', 'none');
    	form.append($('input#user_admin')).css('display', 'none');
    	form.append($('input#user_confirm_new_password')).css('display', 'none');
		form.append($('input#openid')).css('display', 'none');
	}
	if (form.attr('id') === 'login') {
		form.append($('input#user_name')).css('display', 'none');
		form.append($('input#password')).css('display', 'none');
  	}
  });

  // livequery hidden form for link_to ajax magic
  $(document.body).delegate('a[method]', 'click', function(e){
    var $this = $(this);
    var message = $this.attr('confirm'), method = $this.attr('method');

    if (!method && !message) {
      return;
    }

    if (message && !confirm(message)) {
      event.preventDefault();
      return;
    }

    if (method === 'post' || method === 'put' || method === 'delete') {
      event.preventDefault();
      var form = $("<form/>").attr('method', 'post').attr('action', this.href).attr('style', 'display: none');
      if (method !== "post") {
          form.append($('<input type="hidden" name="_method"/>').attr('value', method));
      }
      form.insertAfter(this).submit();
    }
  });
  
  // accordion for the cookbooks show view
	$('.accordion .head').click(function() {
		$(this).next().toggle('slow');
		return false;
	}).next().hide();
	
	// global facebox callback
	$('a[rel*=facebox]').facebox();
	

  $('.connectedSortable').sortable({
    placeholder: 'ui-state-highlight',
    connectWith: $('.connectedSortable')
  }).disableSelection();

  // The table tree!
  $('table.tree').treeTable({ expandable: true });
  $('span.expander').click(function() { $('tr#' + $(this).attr('toggle')).toggleBranch(); });
  
  // Tooltips
  $("div.tooltip").tooltip({ 
      position: ['center', 'right'],
      offset: [-5, 10],
      effect: 'toggle',
      opacity: 0.7 
  });
  
  // Show the sidebars if they have text in them!
  var sidebar_block_notice_children = $("#sidebar_block_notice").children().length;
  var sidebar_block_children = $("#sidebar_block").children().length;
  
  if (sidebar_block_notice_children > 0) {
    $("#sidebar_block_notice").fadeIn();
  }
  
  if (sidebar_block_children > 0) {
    $("#sidebar_block").fadeIn();
  }
});
