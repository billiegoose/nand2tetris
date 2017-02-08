Range = ace.require("ace/range").Range

# TODO: Integrate symbol table and code object so that they work tightly together and each reference each other.
# * Code needs to inject symbols into symbol table.
# * SymbolTable needs to crawl code to find goto label addresses.

init = () ->
  # Set editor 1 for Assembly editing
  asm_editor = ace.edit("asm_editor")
  asm_session = asm_editor.getSession()
  asm_editor.setTheme "ace/theme/monokai"
  asm_session.setMode "ace/mode/asm"
  asm_editor.setOption("firstLineNumber", 0)
  # asm_editor.setFontSize(16) # (in pixels) I don't know if it makes a difference how I set the font size.
  document.getElementById("asm_editor").style.fontSize = "12pt"

  # Set editor 2 for Hack binary editing
  hack_editor = ace.edit("hack_editor")
  hack_session = hack_editor.getSession()
  hack_editor.setTheme "ace/theme/monokai"
  hack_session.setMode "ace/mode/hack"
  document.getElementById("hack_editor").style.fontSize = "12pt"
  hack_editor.renderer.setShowGutter false

  # Synchronize scrollbars - http://stackoverflow.com/a/14751893/2168416
  asm_session.on "changeScrollTop", (scroll) ->
    hack_session.setScrollTop parseInt(scroll) or 0
    return

  hack_session.on "changeScrollTop", (scroll) ->
    asm_session.setScrollTop parseInt(scroll) or 0
    return

  # Show editors
  document.getElementById("editors").style.visibility = "visible"

  # Setup Backbone model(s)
  Instruction = Backbone.Model.extend
    defaults: 
      line_num: null
      final_line_num: null
      type: null
      dest: null
      comp: null
      jump: null
      sym: null
      literal: null
    isInstruction: () ->
      return @attributes.type == "A" || @attributes.type == "C"
    renderHack: (symtable) ->

      address2hack = (num) ->
        out = ""
        for i in [0..15]
          temp = Math.pow(2,i)
          if num > temp
            out += "1"
            num -= temp
          else
            out += "0"

      dest2hack =
        null: "000"
        M   : "001"
        D   : "010"
        MD  : "011"
        A   : "100"
        AM  : "101"
        AD  : "110"
        AMD : "111"

      jump2hack = 
        null: "000"
        JGT : "001"
        JEQ : "010"
        JGE : "011"
        JLT : "100"
        JNE : "101"
        JLE : "110"
        JMP : "111"

      comp2hack = 
        "0"  : "101010"
        "1"  : "111111"
        "-1" : "111010"
        "D"  : "001100"
        "X"  : "110000"
        "!D" : "001101"
        "!X" : "110001"
        "-D" : "001111"
        "-X" : "110011"
        "D+1": "011111"
        "X+1": "110111"
        "D-1": "001110"
        "X-1": "110010"
        "D+X": "000010"
        "D-X": "010011"
        "X-D": "000111"
        "D&X": "000000"
        "D|X": "010101"

      pad15 = (n) ->
        return ("000000000000000" + n)[-15..]

      switch @.get("type")
        when "label"
          return ""
        when "A"
          l = @.get("literal")
          if l?
            a = pad15(l.toString(2))
          else
            s = @.get("sym")
            if s?
              symbol = symtable.findWhere({sym: s}) 
              # If the code is working correctly, it will always be defined. But Just in Case...
              a = if not symbol? then "!!!!!!!!!!!!!!!" else pad15(symbol.get("address").toString(2))
            else
              a = "???????????????"
          return "0" + a
        when "C"
          a = if @.get("comp").search("M") >-1 then "1" else "0"
          comp = @.get("comp").replace(/A|M/, "X")
          return "111" + a + comp2hack[comp] + dest2hack[@.get("dest")] + jump2hack[@.get("jump")]
      return ""

  AsmFile = Backbone.Collection.extend
    model: Instruction
    comparator: "line_num"
    initialize: () ->
      @on "change:type add", (model, collection, options) ->
        @computeFinalLineNumbers()
    renumber: (start_row, offset) ->
      for model in @models[start_row..]
        model.set({line_num: model.attributes.line_num + offset})
    insertLines: (start_row, num_lines) ->
      console.log "Inserting " + num_lines + " lines at " + start_row
      if num_lines == 0 then return
      # Make room
      @renumber start_row, num_lines
      # Create new rows
      for row in [start_row..start_row+num_lines-1]
        @add({line_num: row})
      # Compute new final line number 
      @computeFinalLineNumbers()
      return
    removeLines: (start_row, num_lines) ->
      console.log "Removing " + num_lines + " lines at " + start_row
      if num_lines == 0 then return
      # Delete old rows      
      for row in [start_row...start_row+num_lines]
        @remove(@findWhere({line_num: row}))
      # Renumber remaining lines
      @renumber start_row, -num_lines
      # Compute new final line number 
      @computeFinalLineNumbers()
      return
    computeFinalLineNumbers: () ->
      count = 0
      for r in [0...@models.length]
        model = @models[r]
        if model.isInstruction()
          model.set({final_line_num: count})
          count = count + 1
      return
    renderHack: (model, symtable) ->
      console.log model
      console.log "WWWWTTTFFF" if not model?
      row = model.get("line_num")
      text = model.renderHack(symtable)
      text = model.attributes.final_line_num + ": " + text if model?.isInstruction()
      return text


  window.code = new AsmFile
  window.asm_session = asm_session

  SymbolRow = Backbone.Model.extend 
    defaults:
      sym: null
      address: null
      address_rows: []
      line_num: null
      ref_count: null
      rom: false
      label_row: null
    inc: (row) ->
      # r = @attributes.ref_count
      @attributes.address_rows.append(row)
      @attributes.address_rows.sort()
      @set({ref_count: @attributes.address_rows.length})
      @update_line_num()
    dec: (row) ->
      # r = @attributes.ref_count      
      r = @attributes.address_rows.indexOf(row)
      @attributes.address_rows.splice(r,1)
      @attributes.address_rows.sort()
      @set({ref_count: @attributes.address_rows.length})
      @update_line_num()
    update_line_num: () ->
      if @attributes.address_rows.length == 0
        @set({line_num: null})
      else  
        @set({line_num: @attributes.address_rows[0]})

  SymbolTable = Backbone.Collection.extend
      model: SymbolRow
      comparator: "line_num"
      initialize: () ->
        @on "remove", (model, collection, options) ->
          model.destroy()
          @calc_addresses()
        @on "add", (model, collection, options) ->
          @calc_addresses()
      calc_addresses: () ->
        # In Hack assembly, everything is one word. So our address scheme is dead simple.
        for model, i in @models
          model.set {address: 16 + i}
      reference: (symname, row) ->
        if not symname? then return
        symrow = @findWhere({sym: symname})
        if symrow? then symrow.inc(row) else @add({sym: symname, ref_count: 1})
      dereference: (symname, row) ->
        symrow = @findWhere({sym: symname, address_row: row})
        if symrow? 
          if symrow.get("ref_count") == 1
            console.log "DESTROY!"
            @remove(symrow)
          else
            symrow.dec(row)
        else
          console.log "Bug: dereferenced a symbol that doesn't exist."
      label: (symname, row) ->
        symrow = @findWhere({sym: symname})
        if symrow? then symrow.set({label_row: row})

  window.symtable = new SymbolTable

  # window.symmy = [
  #       {sym:'learn angular', address:true},
  #       {sym:'symbol2', address:false}
  #     ]

  # window.app = angular.module 'SymbolTableApp', []
  # app.controller 'SymbolTableC',
  #   class SymbolTableC
  #     symboltable: symmy
  #     initialize: () ->
  #       window.symtable.on "change", (model) ->
  #         console.log "heyhy"
  #         console.log model

  SymbolRowView = Backbone.View.extend 
    tagName: "tr"
    template: _.template("<td><div><%- sym %></div></td><td><%- address %></td><td><%- ref_count %></td><td><%- label_row %></td>")
    initialize: () ->
      this.listenTo(this.model, "change", this.render);
      this.listenTo(this.model, "destroy", this.remove);
    render: () ->
      this.$el.html(@template(@model.attributes))
      return this
    # initialize: () ->
    #   @listenTo(@model, "change", @render)

  SymbolTableView = Backbone.View.extend
    tagName: "table"
    template: _.template("<tr><th>Symbol</th><th>Address</th><th>Ref</th><th>Label?</th></tr>")
    initialize: () ->
      @listenTo @model, "add", (model, collection, options) ->
        @.$el.append (new SymbolRowView {model: model}).render().$el
    render: () ->
      # Recreate the entire table.
      @.$el.html(@template())
      @model.models.map (model) -> new SymbolRowView {model: model}
        .map ((view) -> @.$el.append view.render().$el), this
      return this

  window.SymbolTableView = SymbolTableView
  window.SymbolRowView = SymbolRowView

  window.hackSetLine = (row, text) ->
    # Make new lines if needed
    if row >= hack_session.getLength()
      for i in [hack_session.getLength()-1..row-1]
        hack_session.insert({row: i, column: Number.MAX_VALUE}, '\n')
    # Set line
    range = new Range(row, 0, row, Number.MAX_VALUE)
    hack_session.replace(range, text)

  code.on "remove", (model) ->
    if model.attributes.sym?
      symtable.dereference(model.attributes.sym, model.attributes.line_num)
    # Hack line will be updated by the change event for the line that replaces this one.
    # Delete left over lines at the end.
    if hack_session.getLength() > code.length
      hack_session.getDocument().removeLines(code.length,hack_session.getLength()-1)

  code.on "add", (model, options) ->
    if model.attributes.sym?
      symtable.reference(model.attributes.sym, model.attributes.line_num)
      if model.attributes.type == "label"
        symtable.label(model.attributes.sym, model.attributes.line_num)

    row = model.get("line_num")
    text = code.renderHack(model, symtable)
    hackSetLine(row,text)

  code.on "change:sym", (model, options) ->
    # Update the reference count
    if model._previousAttributes.sym?
      symtable.dereference(model._previousAttributes.sym, model._previousAttributes.line_num)
    symtable.reference(model.attributes.sym, model.attributes.line_num)

  code.on "change:type", (model, options) ->
    if model._previousAttributes.type == "label"
      console.log "TODO"

  code.on "change", (model, options) ->
    # Update Hack Ace display
    row = model.get("line_num")
    text = code.renderHack(model, symtable)
    hackSetLine(row, text)
    
  window.hack = () ->
    hack_session.setValue("")
    for model in code.models
      hackSetLine(model.get("line_num"),model.renderHack(symtable))
    return

  window.check = () ->
    for i in [0...code.length]
      console.log i + "->" + code.at(i).get("line_num")
    return

  # Build initial code structure from ASM text
  for row in [0...asm_session.getLength()]
    console.log row 
    tokens = asm_session.getTokens(row)
    inst = new Instruction
    inst.set {line_num: row}
    parseLine tokens, inst
    code.add inst

  window.symtable_view = new SymbolTableView({model: symtable, el: $('#symboltable')})
  symtable_view.render()
  console.log "nocrash"

  # Live parsing
  asm_session.on "change", (e) ->
    start = e.data.range.start.row
    end = e.data.range.end.row
    console.log e.data.action + " " + start + "->" + end
    num_rows = end - start
    switch e.data.action
      when "insertLines"
        code.insertLines start, num_rows
        for row in [start..end]
          tokens = asm_session.getTokens(row)
          parseLine tokens, code.at(row)
      when "insertText"
        # For some reason, insertLines is not called when a single newline is added
        if e.data.text == "\n"
          console.log "NEWLINE " + "(" + e.data.range.start.row + "," + e.data.range.start.column + ")->(" + e.data.range.end.row + "," + e.data.range.end.column + ")"
          code.insertLines(end, 1)
        # for all the new or modified rows
        for row in [start..end]
          tokens = asm_session.getTokens(row)
          parseLine tokens, code.at(row)
      when "removeText"
        code.removeLines start, num_rows
        # if e.data.test == "\n"
        # for all the modified rows
        for row in [start..end]
          tokens = asm_session.getTokens(row)
          inst = parseLine tokens, code.at(row)
      when "removeLines"
        code.removeLines start, num_rows


parseLine = (tokens, inst) ->
  tokensearch = (token, regex) ->
    token.type.search(regex) > -1

  # This allows us to iterate through tokens only once,
  # but also trigger appropriate changes for removed values
  # and also only triggers one change by setting it all at once.

  o = 
    type: null
    dest: null
    comp: null
    jump: null
    sym: null
    literal: null
  for t in tokens
    if tokensearch(t, /\bdest\b/)
      o.dest = t.value
    else if tokensearch(t, /\bcomp\b/)
      o.type = "C"
      o.comp = t.value
    else if tokensearch(t, /\bjump\b/)
      o.jump = t.value
    else if tokensearch(t, /\baddress_op\b/)
      o.type = "A"
    else if tokensearch(t, /\bsymbol\b/)
      o.sym = t.value
      if tokensearch(t, /\blabel\b/) then o.type = "label"
    else if tokensearch(t, /\bliteral\b/)
      o.literal = parseInt(t.value)

  inst.set o # {type: o.type, dest: o.dest, comp: o.comp, jump: o.jump, sym: o.sym, literal: o.literal}
  return

# Tokenizer = require("ace/tokenizer").Tokenizer
# ASM = require("ace/mode/asm_highlight_rules")
# asm_highlight_rules = new ASM.AsmHighlightRules
# tokenizer = new Tokenizer(asm_highlight_rules.$rules)

init()