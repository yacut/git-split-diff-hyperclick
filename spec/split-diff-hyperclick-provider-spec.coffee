gitSplitDiffHyperclick = require "../lib/main"

describe "GitSplitDiffHyperclick", ->
  match = (s) ->
    expect(s).toMatch gitSplitDiffHyperclick.getProvider().lineRegExp

  notMatch = (s) ->
    expect(s).not.toMatch gitSplitDiffHyperclick.getProvider().lineRegExp

  describe "wordRegExp", ->
    it "should match git index mask", ->
      match("index d8ebf7f..77f6642 100644")

    it "should match git index mask without permissions", ->
      match("index abcdef0..1234567")

    it "should not match another git diff strings", ->
      notMatch("diff --git")
