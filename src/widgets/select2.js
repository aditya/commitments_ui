(function ($, undefined) {
    "use strict";
    if (window.Select2 !== undefined) {
        return;
    }

    var KEY, AbstractSelect2, MultiSelect2, nextUid, sizer,
        lastMousePosition;

    KEY = {
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


    function markMatch(text, term, markup, escapeMarkup) {
        var match=text.toUpperCase().indexOf(term.toUpperCase()),
            tl=term.length;

        if (match<0) {
            markup.push(escapeMarkup(text));
            return;
        }

        markup.push(escapeMarkup(text.substring(0, match)));
        markup.push("<span class='select2-match'>");
        markup.push(escapeMarkup(text.substring(match, match + tl)));
        markup.push("</span>");
        markup.push(escapeMarkup(text.substring(match + tl, text.length)));
    }

    function evaluate(val) {
        return $.isFunction(val) ? val() : val;
    }
    /**
     * Creates a new class
     *
     * @param superClass
     * @param methods
     */
    function clazz(SuperClass, methods) {
        var constructor = function () {};
        constructor.prototype = new SuperClass;
        constructor.prototype.constructor = constructor;
        constructor.prototype.parent = SuperClass.prototype;
        constructor.prototype = $.extend(constructor.prototype, methods);
        return constructor;
    }

    AbstractSelect2 = clazz(Object, {

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
        // abstract
        bind: function (func) {
            var self = this;
            return function () {
                func.apply(self, arguments);
            };
        },

        // abstract
        init: function (opts) {
            // prepare options
            this.opts = opts = this.prepareOpts(opts);
            this.id=opts.id;
            // destroy if called on an existing component
            if (opts.element.data("select2") !== undefined &&
                opts.element.data("select2") !== null) {
                this.destroy();
            }
            this.enabled=true;
            this.container = this.createContainer();
            this.sizer = this.container.append($("<div class='sizer'/>")).find(".sizer");
            this.elementTabIndex = this.opts.element.attr("tabIndex");
            // swap container for the element
            this.opts.element
                .data("select2", this)
                .addClass("select2-offscreen")
                .bind("focus.select2", function() { $(this).select2("focus"); })
                .attr("tabIndex", "-1")
                .before(this.container);
            this.dropdown = this.container.find(".select2-drop");
            this.dropdown.addClass(evaluate(opts.dropdownCssClass));
            this.search = this.container.find(".select2-input");
            this.search.popover({content: "<ul class='select2-results'></ul>", html: true, placement: "bottom"});
            //forward the tab index, this makes it a lot friendlier for full on
            this.search.attr("tabIndex", this.elementTabIndex);
            this.resultsPage = 0;
            this.context = null;
            this.initContainer();
            // trap all mouse events from leaving the dropdown. sometimes there may be a modal that is listening
            // for mouse events outside of itself so it can close itself. since the dropdown is now outside the select2's
            // dom it will trigger the popup close, which is not what we want
            this.dropdown.bind("click mouseup mousedown", function (e) { e.stopPropagation(); });
            if (opts.element.is(":disabled") || opts.element.is("[readonly='readonly']")) this.disable();
        },
        destroy: function () {
            var select2 = this.opts.element.data("select2");

            if (this.propertyObserver) { delete this.propertyObserver; this.propertyObserver = null; }

            if (select2 !== undefined) {

                select2.container.remove();
                select2.dropdown.remove();
                select2.opts.element
                    .removeClass("select2-offscreen")
                    .removeData("select2")
                    .unbind(".select2")
                    .attr({"tabIndex": this.elementTabIndex})
                    .show();
            }
        },
        populateResults: function(results, query) {
            var addTo = $(".select2-results", this.container);
            addTo.children().remove();
            for (var i = 0; i < results.length; i = i + 1) {
                var result=results[i];
                var node=$("<li></li>");
                node.addClass("select2-result");
                if (result.disabled) { node.addClass("select2-disabled"); }
                var label=$(document.createElement("div"));
                label.addClass("select2-result-label");
                label.html(result);
                node.append(label);
                node.data("select2-data", result);
                addTo.append(node);
            }
        },
        prepareOpts: function (opts) {
            var element, select, idKey;
            element = opts.element;
            opts = $.extend({}, {
            }, $.fn.select2.defaults, opts);
            if (typeof(opts.query) !== "function") {
                throw "query function not defined" + opts.element.attr("id");
            }
            return opts;
        },
        triggerChange: function (details) {
            // prevents recursive triggering
            if(this.opts.element.data("select2-change-triggered")) return;
            details = details || {};
            details= $.extend({}, details, { type: "change", val: this.val() });
            this.opts.element.data("select2-change-triggered", true);
            this.opts.element.trigger(details);
            this.opts.element.data("select2-change-triggered", false);
        },
        enable: function() {
            if (this.enabled) return;
            this.enabled=true;
            this.container.removeClass("select2-container-disabled");
            this.opts.element.removeAttr("disabled");
        },
        // abstract
        disable: function() {
            if (!this.enabled) return;
            this.close();
            this.enabled=false;
            this.container.addClass("select2-container-disabled");
            this.opts.element.attr("disabled", "disabled");
        },
        opened: function () {
            return $(".select2-results", this.container).length;
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
            var results = $(".select2-results", this.container),
                children, index, child, hb, rb, y, more;
            index = this.highlight();
            if (index < 0) return;
            if (index == 0) {
                // if the first element is highlighted scroll all the way to the top,
                // into view
                $(".select2-results", this.container).scrollTop(0);
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
            return $(".select2-result", this.container);
        },
        moveHighlight: function (delta) {
            this.highlight(this.highlight() + delta);
        },
        highlight: function (index) {
            var choices = this.findHighlightableChoices(),
                choice,
                data;
            if (arguments.length === 0) {
                return indexOf(choices.filter(".select2-highlighted")[0], choices.get());
            }
            if (index >= choices.length) index = choices.length - 1;
            if (index < 0) index = 0;
            $(".select2-highlighted", this.container).removeClass("select2-highlighted");
            choice = $(choices[index]);
            choice.addClass("select2-highlighted");
            this.ensureHighlightVisible();
            data = choice.data("select2-data");
            if (data) {
                this.opts.element.trigger({ type: "highlight", val: data, choice: data });
            }
        },
        updateResults: function () {
            var text  = this.search.text();
            if (text.length == 0) return;
            //try to pull out a parseable tag
            var pattern = new RegExp("[" + this.opts.tokenSeparators.join("") + "]+", "g");
            if (text.match(pattern)) {
                this.addSelectedChoice(text.split(pattern)[0]);
                this.clearSearch();
                this.close();
                return;
            }
            //now in a query
            this.search.addClass("select2-active");
            this.opts.query({
                    control: this,
                    term: text,
                    matcher: this.opts.matcher,
                    callback: this.bind(function (data) {
                // ignore a response if the select2 has been closed before it was received
                this.open();
                this.populateResults(data.results, {term: text, page: this.resultsPage, context:null});
                this.ensureSomethingHighlighted();
                this.search.removeClass("select2-active");
            })});
        },
        blur: function () {
            this.clear();
        },
        focusSearch: function () {
            this.search.focus()
            this.resizeSearch(true);
        },
        selectHighlighted: function () {
            var highlighted = $(".select2-highlighted", this.container),
                data = highlighted.closest('.select2-result').data("select2-data");
            if (data) {
                this.onSelect(data)
            }
        },
        initContainerWidth: function () {
            function resolveContainerWidth() {
                var style, attrs, matches, i, l;
                if (this.opts.width === "off") {
                    return null;
                } else if (this.opts.width === "element"){
                    return this.opts.element.outerWidth(false) === 0 ? 'auto' : this.opts.element.outerWidth(false) + 'px';
                } else if (this.opts.width === "copy" || this.opts.width === "resolve") {
                    // check if there is inline style on the element that contains width
                    style = this.opts.element.attr('style');
                    if (style !== undefined) {
                        attrs = style.split(';');
                        for (i = 0, l = attrs.length; i < l; i = i + 1) {
                            matches = attrs[i].replace(/\s/g, '')
                                .match(/width:(([-+]?([0-9]*\.)?[0-9]+)(px|em|ex|%|in|cm|mm|pt|pc))/);
                            if (matches !== null && matches.length >= 1)
                                return matches[1];
                        }
                    }
                    if (this.opts.width === "resolve") {
                        // next check if css('width') can resolve a width that is percent based, this is sometimes possible
                        // when attached to input type=hidden or elements hidden via css
                        style = this.opts.element.css('width');
                        if (style.indexOf("%") > 0) return style;
                        // finally, fallback on the calculated width of the element
                        return (this.opts.element.outerWidth(false) === 0 ? 'auto' : this.opts.element.outerWidth(false) + 'px');
                    }
                    return null;
                } else if ($.isFunction(this.opts.width)) {
                    return this.opts.width();
                } else {
                    return this.opts.width;
               }
            };
            var width = resolveContainerWidth.call(this);
            if (width !== null) {
                this.container.css("width", width);
            }
        }
    });

    MultiSelect2 = clazz(AbstractSelect2, {

        // multi
        createContainer: function () {
            var container = $(document.createElement("div")).attr({
                "class": "select2-container select2-container-multi"
            }).html([
                "<ul class='select2-choices'>",
                "  <li class='select2-search-field'>" ,
                "    <div contentEditable autocomplete='off' class='select2-input'></div>" ,
                "  </li>" ,
                "</ul>"].join(""));
			return container;
        },
        // multi
        prepareOpts: function () {
            var opts = this.parent.prepareOpts.apply(this, arguments);
            return opts;
        },
        // multi
        initContainer: function () {
            var selector = ".select2-choices", selection;
            this.searchContainer = this.container.find(".select2-search-field");
            this.selection = selection = this.container.find(selector);
            this.search.bind("keydown", this.bind(function (e) {
                //key sequences that close
                if (e.which === KEY.BACKSPACE && this.search.text() === "") {
                    this.close();
                    return;
                }
                if (e.which == KEY.ESC) {
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
            this.initContainerWidth();
            // set the placeholder if necessary
            this.clearSearch();
        },
        enable: function() {
            if (this.enabled) return;
            this.parent.enable.apply(this, arguments);
            this.search.removeAttr("disabled");
        },
        disable: function() {
            if (!this.enabled) return;
            this.parent.disable.apply(this, arguments);
            this.search.attr("disabled", true);
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
            this.triggerChange({ added: data });
        },
        cancel: function () {
            this.close();
            this.focusSearch();
        },
        addSelectedChoice: function (data) {
            var item = $(
                "<li class='select2-search-choice'>" +
                "    <span class='icon-remove select2-search-choice-close'></span>" +
                "    <span>" +
                this.opts.escapeMarkup(data) +
                "    </span>" +
                "</li>");
            item.find(".select2-search-choice-close")
                .bind("mousedown", killEvent)
                .bind("click dblclick", this.bind(function (e) {
                  if (!this.enabled) return;
                  $(e.target).closest(".select2-search-choice").fadeOut('fast', this.bind(function(){
                      this.clear();
                  })).dequeue();
                  killEvent(e);
              }));
            item.data("select2-data", data);
            item.insertBefore(this.searchContainer);
            this.values.push(data);
            this.triggerChange();
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
            if (arguments.length === 0) return this.values || [];
            var self = this;
            //the actual data
            this.values = []
            //update the visuals
            this.clearSearch();
            this.selection.find(".select2-search-choice").remove();
            $(arguments[0]).each(function () {
                self.addSelectedChoice(this);
            });
        }
    });
    $.fn.select2 = function () {
        var args = Array.prototype.slice.call(arguments, 0),
            opts,
            select2,
            value, allowedMethods = ["focusSearch", "val", "destroy", "opened", "open", "close", "focus", "container", "enable", "disable", "positionDropdown", "data"];
        this.each(function () {
            if (args.length === 0 || typeof(args[0]) === "object") {
                opts = args.length === 0 ? {} : $.extend({}, args[0]);
                opts.element = $(this);
                select2 = new MultiSelect2()
                select2.init(opts);
            } else if (typeof(args[0]) === "string") {
                if (indexOf(args[0], allowedMethods) < 0) {
                    throw "Unknown method: " + args[0];
                }
                value = undefined;
                select2 = $(this).data("select2");
                if (select2 === undefined) return;
                if (args[0] === "container") {
                    value=select2.container;
                } else {
                    value = select2[args[0]].apply(select2, args.slice(1));
                }
                if (value !== undefined) {return false;}
            } else {
                throw "Invalid arguments to select2 plugin: " + args;
            }
        });
        return (value === undefined) ? this : value;
    };
    // plugin defaults, accessible to users
    $.fn.select2.defaults = {
        formatSelection: function (data, container) {
            return data ? data.text : undefined;
        },
        sortResults: function (results, container, query) {
            return results;
        },
        minimumInputLength: 0,
        maximumInputLength: 128,
        matcher: function(term, text) {
            return text.toUpperCase().indexOf(term.toUpperCase()) >= 0;
        },
        separator: ",",
        tokenSeparators: [],
        escapeMarkup: function (markup) {
            var replace_map = {
                '\\': '&#92;',
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&apos;',
                "/": '&#47;'
            };
            return String(markup).replace(/[&<>"'/\\]/g, function (match) {
                    return replace_map[match[0]];
            });
        }
    };
}(jQuery));
