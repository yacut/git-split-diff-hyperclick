path = require "path"
fs = require "fs"
{Point, Range} = require "atom"
gitRevisionView = require "./git-revision-view.coffee"

module.exports =
  activate: () ->
    require("atom-package-deps").install("git-split-diff-hyperclick")

  getProvider: () ->
    return {
      providerName: "split-diff-hyperclick"
      getSuggestion: (textEditor, point) ->
        if textEditor.getGrammar().name != 'Word Diff' || !textEditor || !point
          return undefined
        else
          editor = textEditor
          rangeIndex = new Range(new Point(point.row, 0), new Point(point.row, 1000))
          gitIndexString = editor.getTextInBufferRange(rangeIndex)
          rangeDiff = new Range(new Point(point.row - 1, 0), new Point(point.row, 1000))
          gitDiffString = editor.getTextInBufferRange(rangeDiff)
          diffMatched = gitDiffString.match /diff --git a\/(.*) b\/(.*)/
          indexMatched = gitIndexString.match /index ([0-9a-f]{7})\.\.([0-9a-f]{7})/
          if !indexMatched || !diffMatched
            return undefined
          else
            [diffMatched, filePathA, filePathB] = gitDiffString.match /diff --git a\/(.*) b\/(.*)/
            [indexMatched, revA, revB] = gitIndexString.match /index ([0-9a-f]{7})\.\.([0-9a-f]{7})/
            return {
              range: rangeIndex,
              callback: ->
                gitRevisionView.showRevision(editor, revA, filePathA, revB, filePathB)
            }
    }
