path = require "path"
fs = require "fs"
{Point, Range} = require "atom"
gitRevisionView = require "./git-revision-view.coffee"

module.exports =
  activate: () ->
    require("atom-package-deps").install("git-split-diff-hyperclick")

  getProvider: () ->
    return {
      lineRegExp: /index [0-9a-f]{7}\.\.[0-9a-f]{7}/g
      providerName: "split-diff-hyperclick"
      getSuggestion: (textEditor, point) ->
        if textEditor.getGrammar().name != 'Word Diff'
          return null
        else
          editor = textEditor
          range = new Range(new Point(point.row, 0), new Point(point.row, 1000))
          indexString = editor.getTextInBufferRange(range)
          match = indexString.match /index ([0-9a-f]{7})\.\.([0-9a-f]{7})/g
          if !match || match is null || match.length is 0
            return null

          return {
            range,
            callback: ->
              gitRevisionView.showRevision(editor, "f747c7e")
          }
    }
