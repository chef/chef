// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.

(function($) {

  function startEditing(elem, options) {
    var editable = $(elem);
    var origHtml = editable.html();
    var origText = options.populate($.trim(editable.text()));

    if (!options.begin.apply(elem, [origText])) {
      return;
    }

    var input = options.createInput.apply(elem, [origText])
      .addClass("editinline").val(origText)
      .dblclick(function() { return false; })
      .keydown(function(evt) {
        switch (evt.keyCode) {
          case 13: { // return
            if (!input.is("textarea")) applyChange(evt.keyCode);
            break;
          }
          case 27: { // escape
            cancelChange(evt.keyCode);
            break;
          }
          case 9: { // tab
            if (!input.is("textarea")) {
              applyChange(evt.keyCode);
              return false;
            }
          }
        }
      });

    function applyChange(keyCode) {
      var newText = input.val();
      if (newText == origText) {
        cancelChange(keyCode);
        return true;
      }
      if ((!options.allowEmpty && !newText.length) ||
          !options.validate.apply(elem, [newText])) {
        input.addClass("invalid");
        return false;
      }
      input.remove();
      tools.remove();
      options.accept.apply(elem, [newText, origText]);
      editable.removeClass("editinline-container");
      options.end.apply(elem, [keyCode]);
      return true;
    }

    function cancelChange(keyCode) {
      options.cancel.apply(elem, [origText]);
      editable.html(origHtml).removeClass("editinline-container");
      options.end.apply(elem, [keyCode]);
    }

    var tools = $("<span class='editinline-tools'></span>");
    $("<button type='button' class='apply'></button>")
      .text(options.acceptLabel).click(applyChange).appendTo(tools);
    $("<button type='button' class='cancel'></button>")
      .text(options.cancelLabel).click(cancelChange).appendTo(tools)

    editable.html("").append(tools).append(input)
      .addClass("editinline-container");
    options.prepareInput.apply(elem, [input[0]]);
    input.each(function() { this.focus(); this.select(); });
  }

  $.fn.makeEditable = function(options) {
    options = $.extend({
      allowEmpty: true,
      acceptLabel: "",
      cancelLabel: "",
      toolTip: "Double click to edit",

      // callbacks
      begin: function() { return true },
      accept: function(newValue, oldValue) {},
      cancel: function(oldValue) {},
      createInput: function(value) { return $("<input type='text'>") },
      prepareInput: function(input) {},
      end: function(keyCode) {},
      populate: function(value) { return value },
      validate: function() { return true }
    }, options || {});

    return this.each(function() {
      $(this).attr("title", options.toolTip).dblclick(function() {
        startEditing(this, options);
      });
    });
  }

})(jQuery);
