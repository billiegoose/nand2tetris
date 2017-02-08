ace.define('ace/mode/asm', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text', 'ace/mode/asm_highlight_rules'], function(require, exports, module) {


var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var AsmHighlightRules = require("./asm_highlight_rules").AsmHighlightRules;

var Mode = function() {
    this.HighlightRules = AsmHighlightRules;
    // this.foldingRules = new FoldMode();
};
oop.inherits(Mode, TextMode);

(function() {
    // this.lineCommentStart = "--";
    // this.blockComment = {start: "/*", end: "*/"};
    this.$id = "ace/mode/asm";
}).call(Mode.prototype);

exports.Mode = Mode;
});

ace.define('ace/mode/asm_highlight_rules', ['require', 'exports', 'module', 'ace/lib/oop', 'ace/mode/text'], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var AsmHighlightRules = function() {

    // regexp must not have capturing parentheses. Use (?:) instead.
    // regexps are ordered -> the first match is used
    this.$rules = {
        "start" : [
            {
                token : "indent",
                regex : '\\s*(?=//)',
                next : "comment"
            }, {
                token : "indent",
                regex : '\\s*(?=\\()',
                next : "label"
            }, {
                token : "indent",
                regex : "\\s*(?=@)",
                next  : "A"
            }, {
                token : "indent",
                regex : "\\s*(?=\\S)",
                next  : "C"
            }, {
                token : "empty",
                regex : '.'
            }
        ],
        "comment" : [
            {
                token : "operator.comment",
                regex : "//"
            }, {
                token : "whitespace",
                regex : "\\s+"
            }, {
                token : "comment",
                regex : ".*",
                next : "start"
            }
        ],
        "label" : [
            {
                token : "open.paren",
                regex : "\\("
            }, {
                token : "label.symbol",
                regex : "[a-zA-Z0-9_\\.\\$\\:]+"
            }, {
                token : "default",
                regex : "(?=.)",
                next  : "end_of_label"
            }
        ],
        "end_of_label" : [
            {
                token : "close.paren",
                regex : "\\)",
                next  : "end_of_line"
            
            }, {
                token : "default",
                regex : "(?=.)",
                next  : "end_of_line"
            }
        ],
        "A" : [
            {
                token : "address_op.string",
                regex : "@"
            }, {
                token : "literal.string",
                regex : "[0-9]+",
                next  : "end_of_line"
            }, {
                token : "symbol.string",
                regex : "[a-zA-Z0-9_\\.\\$\\:]+",
                next  : "end_of_line"
            }, {
                token : "default",
                regex : "(?=.)",
                next  : "end_of_line"
            }
        ],
        "C" : [
            {
                token : "dest.entity.name.function",
                regex : "(?:A|M|D|AM|AD|MD|AMD)(?==)",
                next  : "comp"
            }, {
                token : "error.keyword",
                regex : "[^;/]+(?==)"
            }, {
                token : "default",
                regex : "(?=.)",
                next  : "comp"
            }
        ],
        "comp" : [
            {
                token : "equal_sep.function.name.entity",
                regex : "="
            }, { // 3-letter commands
                token : "comp.support.function", // comp
                regex : "D\\+1|A\\+1|M\\+1|D-1|A-1|M-1|D\\+A|D\\+M|D-A|D-M|A-D|M-D|D&A|D&M|D\\|A|D\\|M",
                next  : "jump"
            }, { // 2-letter commands
                token : "comp.support.function", // comp
                regex : "!D|!A|!M|-D|-A|-M",
                next  : "jump"
            }, { // 3-letter partials
                token : "comp_partial.support.function",
                regex : "A\\+$|M\\+$|D\\+$|A-$|M-$|D-$|D&$|D\\|$",
                next  : "end_of_line"
            }, { // 1-letter commands
                token : "comp.support.function", // comp
                regex : "0|1|-1|D|A|M",
                next  : "jump"
            }, { // 2-letter partials
                token : "comp_partial.support.function",
                regex : "-$|!$",
                next  : "end_of_line"
            }, {
                token : "default",
                regex : "(?=.)",
                next  : "end_of_line"
            }
        ],
        "jump" : [
            {
                token : "jump_sep.constant.numeric",
                regex : ";"
            }, {
                token : "jump.constant.numeric", // jump dest
                regex : "JGT|JEQ|JGE|JLT|JNE|JLE|JMP",
                next  : "end_of_line"
            }, {
                token : "jump_partial.constant.numeric", // partialjump dest
                regex : "J$|JG$|JE$|JL$|JN$|JM$",
                next  : "end_of_line"
            }, {
                token : "default",
                regex : "(?=.)",
                next  : "end_of_line"
            }
        ],
        "dest" : [
            {
                token : "dest",
                regex : "[AMD]*",
                next  : "end_of_line"
            }, {
                token : "error",
                regex : ".*",
                next  : "start"
            }
        ],
        "end_of_line" : [
            {
                token : "whitespace",
                regex : "^",
                next  : "start"
            }, {
                token : "whitespace",
                regex : "$",
                next  : "start"
            }, {
                token : "whitespace",
                regex : "\\s+"
            }, {
                token : "comment",
                regex : "/$"
            }, {
                token : "comment.indent",
                regex : "(?=//)",
                next  : "comment"
            }, {
                token : "error.keyword",
                regex : "."
            }
        ]
    };
    
};

oop.inherits(AsmHighlightRules, TextHighlightRules);

exports.AsmHighlightRules = AsmHighlightRules;
});