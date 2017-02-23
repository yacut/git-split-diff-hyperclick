_ = require 'underscore-plus'
path = require 'path'
fs = require 'fs'

{CompositeDisposable, BufferedProcess} = require "atom"
{$} = require "atom-space-pen-views"

disposables = new CompositeDisposable
SplitDiff = null
SyncScroll = null

module.exports =
class GitRevisionView

  @fileContentA = ""
  @fileContentB = ""
  @showRevision: (revA, filePathA, revB, filePathB) ->
    if not SplitDiff
      try
        SplitDiff = require atom.packages.resolvePackagePath('split-diff')
        SyncScroll = require atom.packages.resolvePackagePath('split-diff') + '/lib/sync-scroll'
        atom.themes.requireStylesheet(atom.packages.resolvePackagePath('split-diff') + '/styles/split-diff')
      catch error
        return atom.notifications.addInfo("Git Plus: Could not load 'split-diff' package to open diff view. Please install it `apm install split-diff`.")

    SplitDiff.disable(false)
    self = @
    self.fileContentA = ""
    self.fileContentB = ""
    self._getRepo(filePathA).then (repo) ->
      if not repo
        cwd = atom.project.getPaths()[0]
      else
        cwd = repo.getWorkingDirectory()
      self._loadfileContentA(cwd, revA, filePathA, revB, filePathB)

  @_loadfileContentA: (cwd, revA, filePathA, revB, filePathB) ->
    self = @
    stdout = (output) ->
      self.fileContentA += output
    stderr = (error) ->
      console.error("git-split-diff-hyperclick:ERROR:", error)
    exit = (code) =>
      if code is 0
        outputFilePath = @_getFilePath(revA, filePathA)
        fs.writeFile outputFilePath, self.fileContentA, (error) ->
          if not error
            promise = atom.workspace.open outputFilePath,
              split: "up"
              activatePane: true
              activateItem: true
              searchAllPanes: false
            promise.then (editorA) ->
              editorA.setSoftWrapped(false)
              self._loadfileContentB(cwd, editorA, revA, filePathA, revB, filePathB)
              try
                disposables.add editorA.onDidDestroy -> fs.unlink outputFilePath
              catch error
                return atom.notifications.addError "Could not remove file #{outputFilePath}"
      else
        atom.notifications.addError "Could not retrieve revision for #{path.basename(filePathA)} (#{code})"

    showArgs = ["cat-file", "-p", "#{revA}"]
    process = new BufferedProcess({
      command: "git",
      args: showArgs,
      options: { cwd:cwd },
      stdout,
      stderr,
      exit
    })

  @_loadfileContentB: (cwd, editorA, revA, filePathA, revB, filePathB) ->
    self = @
    stdout = (output) ->
      self.fileContentB += output
    stderr = (error) ->
      console.error("git-split-diff-hyperclick:ERROR:", error)
    exit = (code) =>
      if code is 0
        @_showRevision(editorA, revA, filePathA, revB, filePathB, self.fileContentB)
      else
        atom.notifications.addError "Could not retrieve revision for #{path.basename(filePathB)} (#{code})"

    showArgs = ["cat-file", "-p", "#{revB}"]
    process = new BufferedProcess({
      command: "git",
      args: showArgs,
      options: { cwd:cwd },
      stdout,
      stderr,
      exit
    })

  @_getFilePath: (rev, filePath) ->
    outputDir = "#{atom.getConfigDirPath()}/git-split-diff-hyperclick"
    fs.mkdir outputDir if not fs.existsSync outputDir
    return "#{outputDir}/#{rev}##{path.basename(filePath)}"

  @_showRevision: (editorA, revA, filePathA, revB, filePathB, fileContentB) ->
    outputFilePath = @_getFilePath(revB, filePathB)
    fs.writeFile outputFilePath, fileContentB, (error) =>
      if not error
        promise = atom.workspace.open outputFilePath,
          split: "right"
          activatePane: true
          activateItem: true
          searchAllPanes: false
        promise.then (editorB) =>
          editorB.setSoftWrapped(false)
          @_splitDiff(editorA, editorB)
          try
            disposables.add editorB.onDidDestroy -> fs.unlink outputFilePath
          catch error
            return atom.notifications.addError "Could not remove file #{outputFilePath}"
          try
            disposables.add editorA.onDidDestroy -> editorB.destroy()
            disposables.add editorB.onDidDestroy -> editorA.destroy()
          catch error
            return atom.notifications.addError "Could not close diff panels."

  @_splitDiff: (editorA, editorB) ->
    editors =
      editor1: editorB    # the older revision
      editor2: editorA           # current rev
    SplitDiff._setConfig 'diffWords', true
    SplitDiff._setConfig 'ignoreWhitespace', true
    SplitDiff._setConfig 'syncHorizontalScroll', true
    SplitDiff.diffPanes()
    SplitDiff.updateDiff(editors)
    syncScroll = new SyncScroll(editors.editor1, editors.editor2, true)
    syncScroll.syncPositions()

  @_getRepo: (filePath) -> new Promise (resolve, reject) ->
    project = atom.project
    filePath = path.join(atom.project.getPaths()[0], filePath)
    directory = project.getDirectories().filter((d) -> d.contains(filePath))[0]
    if directory?
      project.repositoryForDirectory(directory).then (repo) ->
        submodule = repo.repo.submoduleForPath(filePath)
        if submodule? then resolve(submodule) else resolve(repo)
      .catch (e) ->
        reject(e)
    else
      reject "no current file"
