ace.define('ace/mode/hack', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text', 'ace/mode/hack_highlight_rules'], function(require, exports, module) {


var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var HackHighlightRules = require("./hack_highlight_rules").HackHighlightRules;

var Mode = function() {
    this.HighlightRules = HackHighlightRules;
    // this.foldingRules = new FoldMode();
};
oop.inherits(Mode, TextMode);

(function() {
    // this.lineCommentStart = "--";
    // this.blockComment = {start: "/*", end: "*/"};
    this.$id = "ace/mode/hack";
}).call(Mode.prototype);

exports.Mode = Mode;
});

ace.define('ace/mode/hack_highlight_rules', ['require', 'exports', 'module', 'ace/lib/oop', 'ace/mode/text'], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var HackHighlightRules = function() {

    // regexp must not have capturing parentheses. Use (?:) instead.
    // regexps are ordered -> the first match is used
    this.$rules = {
        "start" : [
            {
                token : "line_num",
                regex : ".*:\\s*"
            }, {
                token : "startbit.comment",
                regex : "0",
                next  : "A"
            }, {
                token : "startbit.comment",
                regex : "1",
                next  : "C"
            }, {
                token : "error.keyword",
                regex : ".*$",
                next  : "start"
            }
        ],
        "A" : [
            {
                token : "oops",
                regex : "^",
                next  : "start"
            }, {
                token : "address_op.string",
                regex : "[01]{15}$",
                next  : "start"
            }, {
                token : "error.keyword",
                regex : ".*$",
                next  : "start"
            }
        ],
        "C" : [
            {
                token : "oops",
                regex : "^",
                next  : "start"
            }, {
                token : "C_op.comment",
                regex : "..",
                next  : "a"
            }, {
                token : "error.keyword",
                regex : ".*$",
                next  : "start"
            }
        ],
        "a" : [
            {
                token : "oops",
                regex : "^",
                next  : "start"
            }, {
                token : "a.text", // comp
                regex : "[01]",
                next  : "comp"
            }, {
                token : "a.missing.keyword", // comp
                regex : ".",
                next  : "comp"
            }, {
                token : "error.keyword",
                regex : ".*$",
                next  : "start"
            }
        ],
        "comp" : [
            {
                token : "oops",
                regex : "^",
                next  : "start"
            }, {
                token : "comp.support.function", // comp
                regex : "[01]{6}",
                next  : "dest"
            }, {
                token : "comp.missing.keyword", // comp
                regex : ".{6}",
                next  : "dest"
            }, {
                token : "error.keyword",
                regex : ".*$",
                next  : "start"
            }
        ],
        "dest" : [
            {
                token : "oops",
                regex : "^",
                next  : "start"
            }, {
                token : "dest.entity.name.function",
                regex : "[01]{3}",
                next  : "jump"
            }, {
                token : "dest.missing.keyword",
                regex : ".{3}",
                next  : "jump"
            }, {
                token : "error.keyword",
                regex : ".*$",
                next  : "start"
            }
        ],
        "jump" : [
            {
                token : "oops",
                regex : "^",
                next  : "start"
            }, {
                token : "jump.constant.numeric",
                regex : "[01]{3}",
                next  : "start"
            }, {
                token : "jump.missing.keyword",
                regex : ".{3}",
                next  : "start"
            }, {
                token : "error.keyword",
                regex : ".*$",
                next  : "start"
            }
        ]
    };
    
};

oop.inherits(HackHighlightRules, TextHighlightRules);

exports.HackHighlightRules = HackHighlightRules;
});