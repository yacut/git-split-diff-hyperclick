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
      indexRegex: /index ([0-9a-f]{7})\.\.([0-9a-f]{7})/
      diffRegex: /diff --git a\/(.*) b\/(.*)/
      getSuggestion: (textEditor, point) ->
        if textEditor.getGrammar().name != 'Word Diff' || !textEditor || !point
          return undefined
        else
          editor = textEditor
          rangeIndex = new Range(new Point(point.row, 0), new Point(point.row, 1000))
          gitIndexString = editor.getTextInBufferRange(rangeIndex)
          rangeDiffNamed = new Range(new Point(point.row - 4, 0), new Point(point.row, 1000))
          gitDiffNamedString = editor.getTextInBufferRange(rangeDiffNamed)
          diffNamedMatched = gitDiffNamedString.match this.diffRegex
          rangeDiff = new Range(new Point(point.row - 1, 0), new Point(point.row, 1000))
          gitDiffString = editor.getTextInBufferRange(rangeDiff)
          diffMatched = gitDiffString.match this.diffRegex
          indexMatched = gitIndexString.match this.indexRegex
          if !indexMatched || !(diffMatched|| diffNamedMatched)
            return undefined
          else
            if diffNamedMatched
              [diffMatched, filePathA, filePathB] = gitDiffNamedString.match this.diffRegex
            else
              [diffMatched, filePathA, filePathB] = gitDiffString.match this.diffRegex
            [indexMatched, revA, revB] = gitIndexString.match this.indexRegex
            return {
              range: rangeIndex,
              callback: ->
                gitRevisionView.showRevision(revA, filePathA, revB, filePathB)
            }
    }
