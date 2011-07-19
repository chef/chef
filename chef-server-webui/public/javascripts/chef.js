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

  var buildHiddenFormFromDragDrop = function(form, runListSet) {
    runListSet.each(function(i, envRunListUl) {
      runListItemList = $(envRunListUl).find('li.runListItem')
      if(runListItemList.length == 0){
        activeRunListUl = envRunListUl.getAttribute("class").split(" ").indexOf('active')
        if(activeRunListUl >= 0){
          form.append('<input type="hidden" name="env_run_lists[' + envRunListUl.id + ']"/>');
        }
      }
      else{
        runListItemList.each(function(i, field) {
          form.append('<input type="hidden" name="env_run_lists[' + envRunListUl.id + '][]" value="' + field.id + '"/>');
        });
      }
    });
  };

  var buildHiddenFormFromJSONEditor = function(form) {
    form.append('<input type="hidden" id="default_attributes" name="default_attributes"/>');
    $('input#default_attributes').attr('value', BCJTEP.save('json["defaults"]'));
    form.append('<input type="hidden" id="override_attributes" name="override_attributes"/>');
    $('input#override_attributes').attr('value', BCJTEP.save('json["overrides"]'));
  };

  $('a#debugFormBuild').click(function(event) {buildHiddenFormFromDragDrop(event)});


  $('form.roleForm').submit(function(event) {
    buildHiddenFormFromDragDrop($(this), $('ul.runListItemList'));
    buildHiddenFormFromJSONEditor($(this));
  });

  $('form#edit_environment, form#create_environment').submit(function(event) {
    buildHiddenFormFromJSONEditor($(this));
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


  var enableDragDropBehavior = function() {
    $('.connectedSortable').sortable({
      placeholder: 'ui-state-highlight',
      connectWith: $('.connectedSortable')
    }).disableSelection();
  };

  var disableDragDropBehavior = function() {
    $('.connectedSortable').sortable("destroy");
  };

  enableDragDropBehavior();

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

  // Run list editor with per-env run lists for roles

  var populateAvailableRecipesForEnv = function(currentEnvironment, callback) {
    $.getJSON('/environments/' + currentEnvironment + '/recipes', function(data) {
      $('div#available_recipes_container .spinner').hide();
      for (var i=0; i < data['recipes'].length; i++) {
        var recipe = data['recipes'][i];
        $('ul.availableRecipes').append('<li id="recipe[' + recipe + ']" class="ui-state-default runListItem">' +  recipe + '</li>');
      }
    });
    if (callback) { callback(); }
  };

  var depopulateAvailableRecipesForEnv = function() {
    $('ul.availableRecipes li').remove();
    $('div#available_recipes_container .spinner').show();
  };

  // If the attribute 'data-initial-env' exists on this element, use it to load
  // the recipes for that environment via ajax.
  var initialEnvironment = $('div#environmentRunListSelector').data('initial-env');
  if (initialEnvironment) {
    populateAvailableRecipesForEnv(initialEnvironment);
  }

  var resetAvailableRoleList = function() {
    $('ul#availableRoles li').remove();
    var allRoles = $('ul#availableRoles').data('role-list');
    for (var i=0; i < allRoles.length; i++) {
      var role = allRoles[i];
      $('ul#availableRoles').append('<li id="role[' + role + ']" class="ui-state-highlight runListItem">' + role + '</li>');
    }

  };

  var clearRunListFor = function(environment) {
    $('ul.runListItemList#' + environment).children().remove();
  };

  var removeEnvironmentFromCloneControls = function(environment) {
    $('select.environmentToClone option[value="' + environment + '"]').remove();
  };

  var addEnvironmentToCloneControls = function(environment) {
    $('select.environmentToClone').append('<option value="' + environment + '">' + environment + '</option>');
  };

  var deleteEnvRunList = function(environment) {
    clearRunListFor(environment);
    $('ul.runListItemList#' + environment).removeClass('active').addClass('inactive');
    $('div.emptyRunListControlsContainer#' + environment).removeClass('inactive').addClass('active');
    $('div.runListAdditionalControls#' + environment + " a").remove();
    removeEnvironmentFromCloneControls(environment);
  };

  var createRunListDeleteLinkFor = function(environment) {
    // remove any existing link
    $('a.deleteEnvRunList#' + environment).remove();
    var containerDiv = $('div.runListAdditionalControls#' + environment);
    var link = '<a href="javascript:void(0);" class="deleteEnvRunList" id="' + environment  + '">Remove environment specific run list for ' + environment + '</a>';
    containerDiv.append(link);
    containerDiv.find('a').click(function(j) {deleteEnvRunList(environment);});
  };

  $('a.createEmptyRunListControl').each(function(i) {
    var environment = $(this).attr('id');
    $(this).click(function(event) {
      $('div.emptyRunListControlsContainer#' + environment).removeClass('active').addClass('inactive');
      var runListContainerForEnv = $('div.runListContainer#' + environment + 'RunListContainer');
      $('ul.runListItemList#' + environment).removeClass('inactive').addClass('active');
      // remove all previous drag/drop events/behavior/whatever, then re-add it for the new run list container
      disableDragDropBehavior();
      enableDragDropBehavior();
      createRunListDeleteLinkFor(environment);
      addEnvironmentToCloneControls(environment);
    });
  });

  var setActiveRunListLabelFor = function(environment) {
    var labelElement = $('span#selectedRunListEditorLabel');
    if (environment === '_default') {
      labelElement.html('Default Run List');
    }
    else {
      labelElement.html('Run List for ' + environment);
    }
  };

  $('a.deleteEnvRunList').each(function(i) {
   var environment = $(this).attr('id');
   $(this).click(function(j) {deleteEnvRunList(environment);});
  });

  $('select#activeEnvironment').change(function() {
    // set the active run list editor
    var newActiveEnvironment = $(this).val();
    if (newActiveEnvironment !== 'noop') {
      $('div.runListWithControlsContainer.active').removeClass('active').addClass('inactive');
      $('div.runListWithControlsContainer#' + newActiveEnvironment).addClass('active', 10000).removeClass('inactive');
      setActiveRunListLabelFor(newActiveEnvironment);
      depopulateAvailableRecipesForEnv();
      var selector = $(this);
      populateAvailableRecipesForEnv(newActiveEnvironment, function() { selector.val('noop');});
      resetAvailableRoleList();
    }
  });

  $('select.environmentToClone').change(function() {
    var environmentToClone = $(this).val();
    var targetEnvironment = $(this).attr('id');
    var targetRunList = $('ul.runListItemList#' + targetEnvironment);
    clearRunListFor(targetEnvironment); // be sure we start with a clean slate
    $('ul.runListItemList#' + environmentToClone).children().clone().appendTo(targetRunList);
    $('ul.runListItemList#' + targetEnvironment).removeClass('inactive').addClass('active');
    $('div.emptyRunListControlsContainer#' + targetEnvironment).removeClass('active').addClass('inactive');
    createRunListDeleteLinkFor(targetEnvironment);
    addEnvironmentToCloneControls(targetEnvironment);
  });

  $('select#nodeEnvironment').change(function() {
    // set the active run list editor
    var newNodeEnvironment = $(this).val();
    depopulateAvailableRecipesForEnv();
    populateAvailableRecipesForEnv(newNodeEnvironment);
  });

});
