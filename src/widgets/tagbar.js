(function ($, undefined) {
  "use strict"; if (window.tagbar !== undefined) {
    return;
  }

  function makeATag(data, allowClose, opts) {
    opts = opts || $.fn.tagbar.defaults;
    var item = null;
    if (opts.listItem) {
      var item = $("<li class='tagbar-search-choice'></li>");
    } else {
      var item = $("<span class='tagbar-search-choice'></span>");
    }
    var pattern = new RegExp("[" + opts.tagNamespaceSeparators.join("") + "]+", "g");
    var underZ = 20;
    var icon = null;
    if (opts.iconUrl) {
      var url = opts.iconUrl(data);
      if (url) {
        item.append($("<image class='tagbar-item-icon' src='" + url + "'/>"));
      }
    }
    $.each(data.split(pattern), function(i) {
      var tagbit = $("<span class='tagbar-search-choice-content overlay label'/>");
      tagbit.text(this)
      if (i % 2 == 0) tagbit.addClass("label-info");
      if (i % 2 == 1) tagbit.addClass("label-inverse");
      tagbit.css('z-index', underZ--);
      item.append(tagbit);
    });
    if (allowClose) {
      var closer = $("<span class='closer tagbar-search-choice-close underlay label'><span class='icon-remove-sign'></span></span>");
      item.append(closer);
    }
    return item;
  }

  window.makeATag = makeATag;

  var KEY = {
    TAB: 9,
    ENTER: 13,
    ESC: 27,
    SPACE: 32,
    LEFT: 37,
    UP: 38,
    RIGHT: 39,
    DOWN: 40,
    SHIFT: 16,
    CTRL: 17,
    ALT: 18,
    PAGE_UP: 33,
    PAGE_DOWN: 34,
    HOME: 36,
    END: 35,
    BACKSPACE: 8,
    DELETE: 46
  };

  function indexOf(value, array) {
    var i = 0, l = array.length;
    for (; i < l; i = i + 1) {
      if (equal(value, array[i])) return i;
    }
    return -1;
  }

  function equal(a, b) {
    if (a === b) return true;
    if (a === undefined || b === undefined) return false;
    if (a === null || b === null) return false;
    if (a.constructor === String) return a === b+'';
    if (b.constructor === String) return b === a+'';
    return false;
  }

  function killEvent(event) {
    event.preventDefault();
    event.stopPropagation();
  }

  function killEventImmediately(event) {
    event.preventDefault();
    event.stopImmediatePropagation();
  }

  function evaluate(val) {
    return $.isFunction(val) ? val() : val;
  }

  function TagBar(){ return {
    measureTextWidth: function(e, force) {
      if (e.text().length == 0 && !force)  return 0;
      var style = e[0].currentStyle || window.getComputedStyle(e[0], null);
      this.sizer.css({
        position: "absolute",
        left: "-10000px",
        top: "-10000px",
        display: "none",
        margin: style.margin,
        padding: style.padding,
        fontSize: style.fontSize,
        fontFamily: style.fontFamily,
        fontStyle: style.fontStyle,
        fontWeight: style.fontWeight,
        letterSpacing: style.letterSpacing,
        textTransform: style.textTransform,
        whiteSpace: "nowrap"
      });
      this.sizer.text(e.text() + '__');
      return this.sizer.width();
    },
    bind: function (func) {
      var self = this;
      return function () {
        func.apply(self, arguments);
      };
    },
    init: function (opts) {
      // prepare options
      this.opts = opts = this.prepareOpts(opts);
      this.id=opts.id;
      // destroy if called on an existing component
      if (opts.element.data("tagbar") !== undefined &&
          opts.element.data("tagbar") !== null) {
        this.destroy();
      }
      this.enabled=true;
      this.container = this.createContainer();
      this.sizer = this.container.append($("<div class='sizer'/>")).find(".sizer");
      this.elementTabIndex = this.opts.element.attr("tabIndex");
      this.opts.element.data('tagbar', this).append(this.container);
      this.search = this.container.find(".tagbar-search-field");
      this.search.popover({content: "<ul class='tagbar-results'></ul>", html: true, placement: "bottom"});
      //forward the tab index, this makes it a lot friendlier for full on
      this.search.attr("tabIndex", this.elementTabIndex);
      this.resultsPage = 0;
      this.context = null;
      this.initContainer();
      if (opts.element.is(":disabled") || opts.element.is("[readonly='readonly']")) this.disable();
    },
    destroy: function () {
      this.container.remove();
    },
    populateResults: function(results, query) {
      var addTo = $(".tagbar-results", this.container);
      addTo.children().remove();
      for (var i = 0; i < results.length; i = i + 1) {
        var result=results[i];
        var node=$("<li></li>");
        node.addClass("tagbar-result");
        var label=$(document.createElement("div"));
        label.addClass("tagbar-result-label");
        label.html(result);
        node.append(label);
        node.data("tagbar-data", result);
        addTo.append(node);
      }
    },
    prepareOpts: function (opts) {
      var element, select, idKey;
      element = opts.element;
      //global an instance options
      opts = $.extend({}, $.fn.tagbar.defaults, opts);
      if (typeof(opts.query) !== "function") {
        throw "query function not defined" + opts.element.attr("id");
      }
      return opts;
    },
    triggerChange: function (details) {
      // prevents recursive triggering
      if(this.opts.element.data("tagbar-change-triggered")) return;
      details = details || {};
      details= $.extend({}, details, { type: "change", val: this.val() });
      this.opts.element.data("tagbar-change-triggered", true);
      this.opts.element.trigger(details);
      this.opts.element.data("tagbar-change-triggered", false);
    },
    enable: function() {
      if (this.enabled) return;
      this.enabled=true;
      this.container.removeClass("tagbar-container-disabled");
    },
    disable: function() {
      if (!this.enabled) return;
      this.close();
      this.enabled=false;
      this.container.addClass("tagbar-container-disabled");
    },
    opened: function () {
      return $(".tagbar-results", this.container).length;
    },
    shouldOpen: function() {
      if (this.opened()) return false;
      if (this.search.text().length == 0) return false;
      return true;
    },
    open: function () {
      if (!this.shouldOpen()) return false;
      this.search.popover('show');
      this.focusSearch();
    },
    close: function () {
      if (!this.opened()) return;
      this.search.popover('hide');
    },
    clear: function () {
      this.close();
      this.populateResults([]);
      this.clearSearch();
    },
    ensureHighlightVisible: function () {
      var results = $(".tagbar-results", this.container),
      children, index, child, hb, rb, y, more;
      index = this.highlight();
      if (index < 0) return;
      if (index == 0) {
        // if the first element is highlighted scroll all the way to the top,
        // into view
        $(".tagbar-results", this.container).scrollTop(0);
        return;
      }
      children = this.findHighlightableChoices();
      child = $(children[index]);
      hb = child.offset().top + child.outerHeight(true);
      rb = results.offset().top + results.outerHeight(true);
      if (hb > rb) {
        results.scrollTop(results.scrollTop() + (hb - rb));
      }
      y = child.offset().top - results.offset().top;
      // make sure the top of the element is visible
      if (y < 0 && child.css('display') != 'none' ) {
        results.scrollTop(results.scrollTop() + y); // y is negative
      }
    },
    findHighlightableChoices: function() {
      return $(".tagbar-result", this.container);
    },
    moveHighlight: function (delta) {
      this.highlight(this.highlight() + delta);
    },
    highlight: function (index) {
      var choices = this.findHighlightableChoices(),
      choice,
      data;
      if (arguments.length === 0) {
        return indexOf(choices.filter(".tagbar-highlighted")[0], choices.get());
      }
      if (index >= choices.length) index = choices.length - 1;
      if (index < 0) index = 0;
      $(".tagbar-highlighted", this.container).removeClass("tagbar-highlighted");
      choice = $(choices[index]);
      choice.addClass("tagbar-highlighted");
      this.ensureHighlightVisible();
      data = choice.data("tagbar-data");
      if (data) {
        this.opts.element.trigger({ type: "highlight", val: data, choice: data });
      }
    },
    updateResults: function () {
      var text = this.search.text().trim();
      if (text.length == 0) {
        //you may have a string of spaces, so clean it up
        this.search.text('');
        return;
      }
      //try to pull out a parseable tag
      var pattern = new RegExp("[" + this.opts.tagSeparators.join("") + "]+", "g");
      if (text.match(pattern)) {
        this.addSelectedChoice(text.split(pattern)[0]);
        this.clearSearch();
        this.close();
        return;
      }
      //now in a query
      this.search.addClass("tagbar-active");
      this.opts.query({
        control: this,
        term: text,
        callback: this.bind(function (data) {
          // ignore a response if the tagbar has been closed before it was received
          this.open();
          this.populateResults(data.results, {term: text, page: this.resultsPage, context:null});
          this.ensureSomethingHighlighted();
          this.search.removeClass("tagbar-active");
        })});
    },
    blur: function () {
      this.clear();
      //propagate blur up to the root element
      this.opts.element.trigger('blur');
    },
    focusSearch: function () {
      this.search.focus()
      this.resizeSearch(true);
    },
    selectHighlighted: function () {
      var highlighted = $(".tagbar-highlighted", this.container),
      data = highlighted.closest('.tagbar-result').data("tagbar-data");
      if (data) {
        this.onSelect(data)
      }
    },
    createContainer: function () {
      var container = $(document.createElement("div")).attr({
        "class": "tagbar-container tagbar-container-multi"
      }).html([
        "<ul class='tagbar-choices'>",
        "  <li class='icon icon-" + this.opts.icon + "'></li>",
        "  <li class='tagbar-search-field' contentEditable></li>" ,
        "</ul>"].join(""));
        $(".icon", container).bind("click", this.bind(this.focusSearch));
        return container;
    },
    initContainer: function () {
      this.searchContainer = this.container.find(".tagbar-search-field");
      this.search.bind("keydown", this.bind(function (e) {
        //key sequences that close
        if (e.which === KEY.BACKSPACE && this.search.text() === "") {
          this.close();
          return;
        }
        //if we are opened, key sequences that navigate selected items
        if (this.opened()) {
          switch (e.which) {
            case KEY.UP:
              case KEY.DOWN:
              this.moveHighlight((e.which === KEY.UP) ? -1 : 1);
            killEvent(e);
            return;
            case KEY.ENTER:
              case KEY.TAB:
              this.selectHighlighted();
            killEvent(e);
            return;
            case KEY.ESC:
              this.cancel(e);
            this.search.blur();
            killEvent(e);
            return;
          }
        } else {
          //and when we are closed, key sequences that just exit the field
          switch (e.which) {
            case KEY.ESC:
              case KEY.ENTER:
              this.search.blur();
            killEvent(e);
            return;
          }
        }
      }));
      this.search.bind("input paste focus", this.bind(this.updateResults));
      this.search.bind("input paste focus", this.bind(this.open));
      this.search.bind("blur", this.bind(this.blur));
      this.search.bind("input paste focus", this.bind(this.resizeSearch));
      this.container.bind("click", this.bind(this.focusSearch));
      // set the placeholder if necessary
      this.clearSearch();
    },
    clearSearch: function () {
      this.search.text("");
      this.resizeSearch();
    },
    focus: function () {
      this.focusSearch()
      this.opts.element.triggerHandler("focus");
    },
    onSelect: function (data) {
      this.addSelectedChoice(data);
      this.clear();
      this.focusSearch();
    },
    cancel: function () {
      this.close();
      this.focusSearch();
    },
    addSelectedChoice: function (data, value) {
      var item = makeATag(data, true, this.opts);
      item.find('.closer').bind("click dblclick", this.bind(function (e) {
        if (!this.enabled) return;
        $(e.target).closest(".tagbar-search-choice").fadeOut('fast', this.bind(function(){
          $(e.target).parent(".tagbar-search-choice").remove();
          this.previousValues = _.clone(this.values);
          delete this.values[data];
          this.clear();
          this.triggerChange();
        })).dequeue();
        killEvent(e);
      }));
      item.insertBefore(this.searchContainer);
      this.previousValues = _.clone(this.values);
      this.values[data] = value || Date.now();
    },
    ensureSomethingHighlighted: function () {
      if (this.highlight() == -1){
        this.highlight(0);
      }
    },
    resizeSearch: function (force) {
      var width = this.measureTextWidth(this.search, force);
      this.search.width(width).show()
    },
    val: function () {
      if (arguments.length === 0) return this.values || {};
      var self = this;
      //the actual data needs to be cleared out, will be filled in
      //by adding selected choices
      this.values = {};
      $(".tagbar-search-choice", this.container).remove();
      this.clearSearch();
      //now add in all the items, forgiving the input as an array
      if (Array.isArray(arguments[0])) {
        $(arguments[0]).each(function () {
          self.addSelectedChoice(this);
        });
        this.triggerChange();
      } else {
        for (var tag in arguments[0]){
          self.addSelectedChoice(tag, arguments[0][tag]);
        }
      }
    },
    previous: function () {
      return this.previousValues || {};
    },
  };}
  $.fn.tagbar = function () {
    var args = Array.prototype.slice.call(arguments, 0),
    opts,
    value, allowedMethods = ["focusSearch", "val", "previous", "destroy", "opened", "open", "close", "focus", "container", "enable", "disable", "data"];
    this.each(function () {
      if (args.length === 0 || typeof(args[0]) === "object") {
        opts = args.length === 0 ? {} : $.extend({}, args[0]);
        opts.element = $(this);
        opts.listItem = true;
        new TagBar().init(opts);
      } else if (typeof(args[0]) === "string") {
        if (indexOf(args[0], allowedMethods) < 0) {
          throw "Unknown method: " + args[0];
        }
        value = undefined;
        var tagbar = $(this).data("tagbar");
        if (args[0] === "container") {
          value=tagbar.container;
        } else {
          value = tagbar[args[0]].apply(tagbar, args.slice(1));
        }
        if (value !== undefined) {return false;}
      } else {
        throw "Invalid arguments to plugin: " + args;
      }
    });
    return (value === undefined) ? this : value;
  };
  // plugin defaults, accessible to users
  $.fn.tagbar.defaults = {
    minimumInputLength: 0,
    maximumInputLength: 128,
    tagSeparators: [',', ';'],
    tagNamespaceSeparators: ['/', ':'],
  };
}(jQuery));
