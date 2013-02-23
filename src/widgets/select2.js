
(function ($, undefined) {
    "use strict";
    if (window.Select2 !== undefined) {
        return;
    }

    var KEY, AbstractSelect2, MultiSelect2, nextUid, sizer,
        lastMousePosition, $document;

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
        DELETE: 46,
        isArrow: function (k) {
            k = k.which ? k.which : k;
            switch (k) {
            case KEY.LEFT:
            case KEY.RIGHT:
            case KEY.UP:
            case KEY.DOWN:
                return true;
            }
            return false;
        },
        isControl: function (e) {
            var k = e.which;
            switch (k) {
            case KEY.SHIFT:
            case KEY.CTRL:
            case KEY.ALT:
                return true;
            }

            if (e.metaKey) return true;

            return false;
        },
        isFunctionKey: function (k) {
            k = k.which ? k.which : k;
            return k >= 112 && k <= 123;
        }
    };

    $document = $(document);

    nextUid=(function() { var counter=1; return function() { return counter++; }; }());

    function indexOf(value, array) {
        var i = 0, l = array.length;
        for (; i < l; i = i + 1) {
            if (equal(value, array[i])) return i;
        }
        return -1;
    }

    /**
     * Compares equality of a and b
     * @param a
     * @param b
     */
    function equal(a, b) {
        if (a === b) return true;
        if (a === undefined || b === undefined) return false;
        if (a === null || b === null) return false;
        if (a.constructor === String) return a === b+'';
        if (b.constructor === String) return b === a+'';
        return false;
    }

    /**
     * Splits the string into an array of values, trimming each value. An empty array is returned for nulls or empty
     * strings
     * @param string
     * @param separator
     */
    function splitVal(string, separator) {
        var val, i, l;
        if (string === null || string.length < 1) return [];
        val = string.split(separator);
        for (i = 0, l = val.length; i < l; i = i + 1) val[i] = $.trim(val[i]);
        return val;
    }

    /**
     * A simple implementation of a thunk
     * @param formula function used to lazily initialize the thunk
     * @return {Function}
     */
    function thunk(formula) {
        var evaluated = false,
            value;
        return function() {
            if (evaluated === false) { value = formula(); evaluated = true; }
            return value;
        };
    };

    function killEvent(event) {
        event.preventDefault();
        event.stopPropagation();
    }

    function killEventImmediately(event) {
        event.preventDefault();
        event.stopImmediatePropagation();
    }

    function measureTextWidth(e, force) {
        if (e.text().length == 0 && !force)  return 0;
        if (!sizer){
        	sizer = $(document.createElement("div"));
        	$("body").append(sizer);
        }
      	var style = e[0].currentStyle || window.getComputedStyle(e[0], null);
        sizer.css({
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
        sizer.text(e.text() + '__');
        return sizer.width();
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

    function countResults(results) {
        var count = 0;
        $.each(results, function(i, item) {
            if (item.children) {
                count += countResults(item.children);
            } else {
                count++;
            }
        });
        return count;
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

        // abstract
        bind: function (func) {
            var self = this;
            return function () {
                func.apply(self, arguments);
            };
        },

        // abstract
        init: function (opts) {
            var results, search, resultsSelector = ".select2-results", mask;
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
            this.containerId="s2id_"+(opts.element.attr("id") || "autogen"+nextUid());
            this.containerSelector="#"+this.containerId.replace(/([;&,\.\+\*\~':"\!\^#$%@\[\]\(\)=>\|])/g, '\\$1');
            this.container.attr("id", this.containerId);
            // cache the body so future lookups are cheap
            this.body = thunk(function() { return opts.element.closest("body"); });
            this.elementTabIndex = this.opts.element.attr("tabIndex");
            // swap container for the element
            this.opts.element
                .data("select2", this)
                .addClass("select2-offscreen")
                .bind("focus.select2", function() { $(this).select2("focus"); })
                .attr("tabIndex", "-1")
                .before(this.container);
            this.container.data("select2", this);
            this.dropdown = this.container.find(".select2-drop");
            this.dropdown.addClass(evaluate(opts.dropdownCssClass));
            this.dropdown.data("select2", this);
            this.results = results = this.container.find(resultsSelector);
            this.search = search = this.container.find(".select2-input");
            //forward the tab index, this makes it a lot friendlier for full on
            search.attr("tabIndex", this.elementTabIndex);
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
        populateResults: function(container, results, query) {
            for (var i = 0; i < results.length; i = i + 1) {
                var result=results[i];
                var node=$("<li></li>");
                node.addClass("select2-result");
                if (result.disabled) { node.addClass("select2-disabled"); }
                node.addClass(self.opts.formatResultCssClass(result));
                var label=$(document.createElement("div"));
                label.addClass("select2-result-label");
                var formatted=opts.formatResult(result, label, query, self.opts.escapeMarkup);
                if (formatted!==undefined) {
                    label.html(formatted);
                }
                node.append(label);
                node.data("select2-data", result);
                container.append(node);
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
            return this.container.hasClass("select2-dropdown-open");
        },
        positionDropdown: function() {
            var offset = this.container.offset(),
                height = this.container.outerHeight(false),
                width = this.container.outerWidth(false),
                dropHeight = this.dropdown.outerHeight(false),
	            viewPortRight = $(window).scrollLeft() + $(window).width(),
                viewportBottom = $(window).scrollTop() + $(window).height(),
                dropTop = offset.top + height,
                dropLeft = offset.left,
                enoughRoomBelow = dropTop + dropHeight <= viewportBottom,
                enoughRoomAbove = (offset.top - dropHeight) >= this.body().scrollTop(),
	            dropWidth = this.dropdown.outerWidth(false),
	            enoughRoomOnRight = dropLeft + dropWidth <= viewPortRight,
                aboveNow = this.dropdown.hasClass("select2-drop-above"),
                bodyOffset,
                above,
                css;

            // fix positioning when body has an offset and is not position: static

            if (this.body().css('position') !== 'static') {
                bodyOffset = this.body().offset();
                dropTop -= bodyOffset.top;
                dropLeft -= bodyOffset.left;
            }

            // always prefer the current above/below alignment, unless there is not enough room

            if (aboveNow) {
                above = true;
                if (!enoughRoomAbove && enoughRoomBelow) above = false;
            } else {
                above = false;
                if (!enoughRoomBelow && enoughRoomAbove) above = true;
            }

            if (!enoughRoomOnRight) {
               dropLeft = offset.left + width - dropWidth;
            }

            if (above) {
                dropTop = offset.top - dropHeight;
                this.container.addClass("select2-drop-above");
                this.dropdown.addClass("select2-drop-above");
            }
            else {
                this.container.removeClass("select2-drop-above");
                this.dropdown.removeClass("select2-drop-above");
            }

            css = $.extend({
                top: dropTop,
                left: dropLeft,
                width: width
            }, evaluate(this.opts.dropdownCss));

            this.dropdown.css(css);
        },

        // abstract
        shouldOpen: function() {
            if (this.opened()) return false;
            if (this.search.text().length == 0) return false;

            event = $.Event("opening");
            this.opts.element.trigger(event);
            return !event.isDefaultPrevented();
        },

        // abstract
        clearDropdownAlignmentPreference: function() {
            // clear the classes used to figure out the preference of where the dropdown should be opened
            this.container.removeClass("select2-drop-above");
            this.dropdown.removeClass("select2-drop-above");
        },
        open: function () {
            if (!this.shouldOpen()) return false;
            window.setTimeout(this.bind(this.opening), 1);
            return true;
        },
        opening: function() {
            var cid = this.containerId,
                scroll = "scroll." + cid,
                resize = "resize."+cid,
                orient = "orientationchange."+cid,
                mask;
            this.clearDropdownAlignmentPreference();
            this.container.addClass("select2-dropdown-open").addClass("select2-container-active");
            if(this.dropdown[0] !== this.body().children().last()[0]) {
                this.dropdown.detach().appendTo(this.body());
            }
            // create the dropdown mask if doesnt already exist
            mask = $("#select2-drop-mask");
            if (mask.length == 0) {
                mask = $(document.createElement("div"));
                mask.attr("id","select2-drop-mask").attr("class","select2-drop-mask");
                mask.hide();
                mask.appendTo(this.body());
                mask.bind("mousedown touchstart", function (e) {
                    var dropdown = $("#select2-drop"), self;
                    if (dropdown.length > 0) {
                        self=dropdown.data("select2");
                        if (self.opts.selectOnBlur) {
                            self.selectHighlighted({noFocus: true});
                        }
                        self.close();
                    }
                });
            }

            // ensure the mask is always right before the dropdown
            if (this.dropdown.prev()[0] !== mask[0]) {
                this.dropdown.before(mask);
            }

            // move the global id to the correct dropdown
            $("#select2-drop").removeAttr("id");
            this.dropdown.attr("id", "select2-drop");

            // show the elements
            mask.css({
                width: document.documentElement.scrollWidth,
                height: document.documentElement.scrollHeight});
            mask.show();
            this.dropdown.show();
            this.positionDropdown();

            this.dropdown.addClass("select2-drop-active");
            this.ensureHighlightVisible();

            // attach listeners to events that can change the position of the container and thus require
            // the position of the dropdown to be updated as well so it does not come unglued from the container
            var that = this;
            this.container.parents().add(window).each(function () {
                $(this).bind(resize+" "+scroll+" "+orient, function (e) {
                    $("#select2-drop-mask").css({
                        width:document.documentElement.scrollWidth,
                        height:document.documentElement.scrollHeight});
                    that.positionDropdown();
                });
            });

            this.focusSearch();
            this.opts.element.trigger("open");
        },

        // abstract
        close: function () {
            if (!this.opened()) return;

            var cid = this.containerId,
                scroll = "scroll." + cid,
                resize = "resize."+cid,
                orient = "orientationchange."+cid;

            // unbind event listeners
            this.container.parents().add(window).each(function () { $(this).unbind(scroll).unbind(resize).unbind(orient); });

            this.clearDropdownAlignmentPreference();

            $("#select2-drop-mask").hide();
            this.dropdown.removeAttr("id"); // only the active dropdown has the select2-drop id
            this.dropdown.hide();
            this.container.removeClass("select2-dropdown-open");
            this.results.empty();
            this.clearSearch();

            this.opts.element.trigger("close");
        },

        // abstract
        clearSearch: function () {

        },

        //abstract
        getMaximumSelectionSize: function() {
            return evaluate(this.opts.maximumSelectionSize);
        },

        // abstract
        ensureHighlightVisible: function () {
            var results = this.results, children, index, child, hb, rb, y, more;

            index = this.highlight();

            if (index < 0) return;

            if (index == 0) {
                // if the first element is highlighted scroll all the way to the top,
                // into view
                results.scrollTop(0);
                return;
            }

            children = this.findHighlightableChoices();

            child = $(children[index]);

            hb = child.offset().top + child.outerHeight(true);

            // if this is the last child lets also make sure select2-more-results is visible
            if (index === children.length - 1) {
                more = results.find("li.select2-more-results");
                if (more.length > 0) {
                    hb = more.offset().top + more.outerHeight(true);
                }
            }

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

        // abstract
        findHighlightableChoices: function() {
            return this.results.find(".select2-result");
        },

        // abstract
        moveHighlight: function (delta) {
            var choices = this.findHighlightableChoices(),
                index = this.highlight();
            while (index > -1 && index < choices.length) {
                index += delta;
                var choice = $(choices[index]);
                result = choice
                if (choice.hasClass("select2-result-selectable") && !choice.hasClass("select2-disabled") && !choice.hasClass("select2-selected")) {
                    this.highlight(index);
                    break;
                }
            }
        },

        // abstract
        highlight: function (index) {
            var choices = this.findHighlightableChoices(),
                choice,
                data;

            if (arguments.length === 0) {
                return indexOf(choices.filter(".select2-highlighted")[0], choices.get());
            }

            if (index >= choices.length) index = choices.length - 1;
            if (index < 0) index = 0;

            this.results.find(".select2-highlighted").removeClass("select2-highlighted");

            choice = $(choices[index]);
            choice.addClass("select2-highlighted");

            this.ensureHighlightVisible();

            data = choice.data("select2-data");
            if (data) {
                this.opts.element.trigger({ type: "highlight", val: this.id(data), choice: data });
            }
        },

        // abstract
        countSelectableResults: function() {
            return this.findHighlightableChoices().length;
        },

        // abstract
        highlightUnderEvent: function (event) {
            var el = $(event.target).closest(".select2-result-selectable");
            if (el.length > 0 && !el.is(".select2-highlighted")) {
        		var choices = this.findHighlightableChoices();
                this.highlight(choices.index(el));
            } else if (el.length == 0) {
                // if we are over an unselectable item remove al highlights
                this.results.find(".select2-highlighted").removeClass("select2-highlighted");
            }
        },
        updateResults: function () {
            var text  = this.search.text();
            //try to pull out a parseable tag
            var pattern = new RegExp("[" + this.opts.tokenSeparators.join("") + "]+", "g");
            console.log(text.split(pattern), pattern, text.match(pattern));
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
                if (!this.opened()) return;
                this.populateResults(this, data, {term: text, page: this.resultsPage, context:null});
                this.ensureSomethingHighlighted();
                this.search.removeClass("select2-active");
                this.positionDropdown();
            })});
        },
        blur: function () {
            // if selectOnBlur == true, select the currently highlighted option
            if (this.opts.selectOnBlur)
                this.selectHighlighted({noFocus: true});

            this.close();
            this.container.removeClass("select2-container-active");
            // synonymous to .is(':focus'), which is available in jquery >= 1.6
            if (this.search[0] === document.activeElement) { this.search.blur(); }
            this.clearSearch();
            this.selection.find(".select2-search-choice-focus").removeClass("select2-search-choice-focus");
        },

        // abstract
        focusSearch: function () {
            this.search.focus()
            this.resizeSearch(true);
        },

        // abstract
        selectHighlighted: function (options) {
            var index=this.highlight(),
                highlighted=this.results.find(".select2-highlighted"),
                data = highlighted.closest('.select2-result').data("select2-data");

            if (data) {
                this.highlight(index);
                this.onSelect(data, options);
            }
        },

        // abstract
        getPlaceholder: function () {
            return this.opts.element.attr("placeholder") ||
                this.opts.element.attr("data-placeholder") || // jquery 1.4 compat
                this.opts.element.data("placeholder") ||
                this.opts.placeholder;
        },

        /**
         * Get the desired width for the container element.  This is
         * derived first from option `width` passed to select2, then
         * the inline 'style' on the original element, and finally
         * falls back to the jQuery calculated element width.
         */
        // abstract
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
                "</ul>" ,
                "<div class='select2-drop select2-drop-multi' style='display:none;'>" ,
                "   <ul class='select2-results'>" ,
                "   </ul>" ,
                "</div>"].join(""));
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
            this.search.bind("input paste", this.bind(this.updateResults));
            this.search.bind("input paste", this.bind(this.open));
            //resize the search box all the time, this expands as we type
            this.search.bind("input paste", this.bind(this.resizeSearch));
            this.search.bind("keyup", this.bind(function (e) {
                if (!this.enabled) return;
                //key sequences that close
                if (e.which === KEY.BACKSPACE && this.search.text() === "") {
                    this.close();
                    return;
                }
                if (e.which == KEY.ESC) {
                    this.close();
                    return;
                }
                if (e.which === KEY.TAB || KEY.isControl(e) || KEY.isFunctionKey(e)
                 || e.which === KEY.BACKSPACE || e.which === KEY.ESC || e.which == KEY.ENTER) {
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
                //everything else opens
                this.open();
            }));
            this.container.delegate(selector, "focus", this.bind(function () {
                if (!this.enabled) return;
                this.container.addClass("select2-container-active");
                this.dropdown.addClass("select2-drop-active");
            }));
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
            this.close();
            this.focusSearch()
            this.opts.element.triggerHandler("focus");
        },
        onSelect: function (data, options) {
            this.addSelectedChoice(data);
            this.clearSearch();
            this.close();
            this.resizeSearch();
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
                      this.cancel();
                  })).dequeue();
                  killEvent(e);
              })).bind("focus", this.bind(function () {
                  if (!this.enabled) return;
                  this.container.addClass("select2-container-active");
                  this.dropdown.addClass("select2-drop-active");
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
            var width = measureTextWidth(this.search, force);
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
        formatResult: function(result, container, query, escapeMarkup) {
            var markup=[];
            markMatch(result.text, query.term, markup, escapeMarkup);
            return markup.join("");
        },
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
