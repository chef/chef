//
// Author:: Adam Jacob (<adam@opscode.com>)
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

$(document).ready(function() {
  $(".edit_area").editable(location.href + ".json", { 
      type      : 'textarea',
      cancel    : 'Cancel',
      submit    : 'Save',
      indicator : "<img src='/images/indicator.gif'>",
      target    : location.href + "?ajax=true",
      loadtype  : "GET",
      loadurl   : location.href + ".json?ajax=true",
      tooltip   : 'Click to edit...',
      method : "PUT"
  });
});

$(document).ready(function() {
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
});