'use babel';

import pathHyperclick from "../lib/main";

describe("PathHyperclickProvider", () => {
  function match(s) {
    expect(s).toMatch(pathHyperclick.getProvider().wordRegExp);
  }

  function notMatch(s) {
    expect(s).not.toMatch(pathHyperclick.getProvider().wordRegExp);
  }

  describe("wordRegExp", () => {
    it("should match git index mask", () => {
      match("index d8ebf7f..77f6642 100644");
    });

    it("should match git index mask without permissions", () => {
      match("index abcdef0..1234567");
    });

    it("should not match another git diff strings", () => {
      match("diff --git");
    });
  });
});
