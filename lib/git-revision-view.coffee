_ = require 'underscore-plus'
path = require 'path'
fs = require 'fs'

{CompositeDisposable, BufferedProcess} = require "atom"
{$} = require "atom-space-pen-views"

SplitDiff = require 'split-diff'


module.exports =
class GitRevisionView

  fileContentA = ""
  fileContentB = ""
  @showRevision: (editor, revA, filePathA, revB, filePathB) ->
    SplitDiff.disable(false)
    fileContentA = ""
    fileContentB = ""
    promise = @_getRepo(filePathA)
    @_loadFileContentA(editor, revA, filePathA, revB, filePathB)

  @_loadFileContentA: (editorA, revA, filePathA, revB, filePathB) ->
    fileContentA = ""
    stdout = (output) ->
      console.log("OUTPUT", output)
      fileContentA += output
    stderr = (error) ->
      console.log("git-split-diff-hyperclick:ERROR:", error)
    exit = (code) =>
      console.log("CODE", code, fileContentA)
      if code is 0
        outputFilePath = @_getFilePath(revA, filePathA)
        tempContent = "Loading..." + editor.buffer?.lineEndingForRow(0)
        fs.writeFile outputFilePath, tempContent, (error) ->
          if not error
            promise = atom.workspace.open fullPath,
              split: "left"
              activatePane: false
              activateItem: true
              searchAllPanes: false
            promise.then (editor) ->
              @_loadFileContentB(editorA, revA, filePathA, revB, filePathB)
      else
        atom.notifications.addError "Could not retrieve revision for #{path.basename(filePathA)} (#{code})"

    showArgs = ["show", "#{revA} ./#{filePathA}"]
    console.log('LOAD A', showArgs, filePathA)
    process = new BufferedProcess({
      command: "git",
      args: showArgs,
      options: { cwd:atom.project.getPaths()[0] },
      stdout,
      stderr,
      exit
    })

  @_loadFileContentB: (editorA, revA, filePathA, revB, filePathB) ->

    stdout = (output) ->
      fileContentB += output
    stderr = (error) ->
      console.log("git-split-diff-hyperclick:ERROR:", error)
    exit = (code) =>
      if code is 0
        @_showRevision(editorA, revA, filePathA, revB, filePathB, fileContentA, fileContentB)
      else
        atom.notifications.addError "Could not retrieve revision for #{path.basename(filePathB)} (#{code})"

    showArgs = ["show", "#{revB}:./#{filePathB}"]
    console.log('LOAD B', showArgs, filePathB)
    process = new BufferedProcess({
      command: "git",
      args: showArgs,
      options: { cwd:atom.project.getPaths()[0] },
      stdout,
      stderr,
      exit
    })

  @_getInitialLineNumber: (editor) ->
    editorEle = atom.views.getView editor
    lineNumber = 0
    if editor? && editor != ''
      lineNumber = editorEle.getLastVisibleScreenRow()
      return lineNumber - 5

  @_getFilePath: (rev, filePath) ->
    outputDir = "#{atom.getConfigDirPath()}/git-plus"
    fs.mkdir outputDir if not fs.existsSync outputDir
    return "#{outputDir}/#{rev}#{path.basename(filePath)}.diff"

  @_showRevision: (editorA, revA, filePathA, revB, filePathB) ->
    outputFilePath = @_getFilePath(revB, filePathB)
    tempContent = "Loading..." + editor.buffer?.lineEndingForRow(0)
    fs.writeFile outputFilePath, tempContent, (error) =>
      if not error
        promise = atom.workspace.open file,
          split: "left"
          activatePane: false
          activateItem: true
          searchAllPanes: false
        promise.then (editor) =>
          promise = atom.workspace.open outputFilePath,
            split: "right"
            activatePane: false
            activateItem: true
            searchAllPanes: false
          promise.then (editorB) =>
            @_updateNewTextEditor(editorA, editorB, revA, filePathA, revB, filePathB, fileContents)


  @_updateNewTextEditor: (editorA, editorB, gitRevision, fileContents) ->
    _.delay =>
      lineEnding = editor.buffer?.lineEndingForRow(0) || "\n"
      fileContents = fileContents.replace(/(\r\n|\n)/g, lineEnding)
      editorB.buffer.setPreferredLineEnding(lineEnding)
      editorB.setText(fileContents)
      editorB.buffer.cachedDiskContents = fileContents
      @_splitDiff(editor, editorB)
      @_syncScroll(editor, editorB)
      @_affixTabTitle editorB, gitRevision
    , 300


  @_affixTabTitle: (newTextEditor, gitRevision) ->
    $el = $(atom.views.getView(newTextEditor))
    $tabTitle = $el.parents('atom-pane').find('li.tab.active .title')
    titleText = $tabTitle.text()
    if titleText.indexOf('@') >= 0
      titleText = titleText.replace(/\@.*/, "@#{gitRevision}")
    else
      titleText += " @#{gitRevision}"
    $tabTitle.text(titleText)


  @_splitDiff: (editor, newTextEditor) ->
    editors =
      editor1: newTextEditor    # the older revision
      editor2: editor           # current rev
    SplitDiff._setConfig 'rightEditorColor', 'green'
    SplitDiff._setConfig 'leftEditorColor', 'red'
    SplitDiff._setConfig 'diffWords', true
    SplitDiff._setConfig 'ignoreWhitespace', true
    SplitDiff._setConfig 'syncHorizontalScroll', true
    SplitDiff.editorSubscriptions = new CompositeDisposable()
    SplitDiff.editorSubscriptions.add editors.editor1.onDidStopChanging ->
      SplitDiff.updateDiff(editors) if editors?
    SplitDiff.editorSubscriptions.add editors.editor2.onDidStopChanging ->
      SplitDiff.updateDiff(editors) if editors?
    SplitDiff.editorSubscriptions.add editors.editor1.onDidDestroy ->
      editors = null
      SplitDiff.disable(false)
    SplitDiff.editorSubscriptions.add editors.editor2.onDidDestroy ->
      editors = null
      SplitDiff.disable(false)
    SplitDiff.updateDiff editors


  @_syncScroll: (editor, newTextEditor) ->
    _.delay =>
      return if newTextEditor.isDestroyed()
      newTextEditor.scrollToBufferPosition({row: @_getInitialLineNumber(editor), column: 0})
    , 50

  @_getRepo: (filePath) ->
    new Promise (resolve, reject) ->
      project = atom.project
      filePath = path.join(atom.project.getPaths()[0], filePath)
      console.log("PATH", filePath)
      directory = project.getDirectories().filter((d) -> d.contains(filePath))[0]
      if directory?
        project.repositoryForDirectory(directory).then (repo) ->
          submodule = repo.repo.submoduleForPath(filePath)
          if submodule? then resolve(submodule) else resolve(repo)
        .catch (e) ->
          reject(e)
      else
        reject "no current file"
