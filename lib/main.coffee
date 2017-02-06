path = require "path"
fs = require "fs"
gitRevisionView = require "./git-revision-view.coffee"

module.exports =
  #  activate() {
  #    require("atom-package-deps").install("split-diff-hyperclick");
  #  },
  getProvider: () ->
    return {
      # wordRegExp: /[0-9a-f]{7}\.\.[0-9a-f]{7}/g,
      providerName: "split-diff-hyperclick"
      getSuggestion: (textEditor, indexString, range) ->
        console.log('getSuggestionForWord', textEditor, indexString, range)
        match = indexString.match /index ([0-9a-f]{7})\.\.([0-9a-f]{7})/g
        return {
          range,
          callback: ->
            if match is undefined || match.length is 0
              return
            console.log('getSuggestionForWord.match', match)
        }
    }
