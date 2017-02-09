gitSplitDiffHyperclick = require "../lib/main"

describe "GitSplitDiffHyperclick", ->
  indexMatch = (s) ->
    expect(s).toMatch gitSplitDiffHyperclick.getProvider().indexRegex

  indexNotMatch = (s) ->
    expect(s).not.toMatch gitSplitDiffHyperclick.getProvider().indexRegex

  describe "Index regex", ->
    it "should match git index mask", ->
      indexMatch("index d8ebf7f..77f6642 100644")

    it "should match git index mask without permissions", ->
      indexMatch("index abcdef0..1234567")

    it "should not match another strings", ->
      indexNotMatch("whatever")

  diffMatch = (s) ->
    expect(s).toMatch gitSplitDiffHyperclick.getProvider().diffRegex

  diffNotMatch = (s) ->
    expect(s).not.toMatch gitSplitDiffHyperclick.getProvider().diffRegex

  describe "Diff regex", ->
    it "should match git index mask", ->
      diffMatch("diff --git a/foo.bar b/foo.bar")

    it "should not match another index strings", ->
      diffNotMatch("index abcdef0..1234567")
