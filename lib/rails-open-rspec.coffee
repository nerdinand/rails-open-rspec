RailsOpenRspecView = require './rails-open-rspec-view'
SpecWriter = require './spec-writer'

{CompositeDisposable} = require 'atom'
{TextEditor} = require 'atom'

fs = require 'fs'
Path = require 'path'

RAILS_ROOT = atom.project.getPaths()[0]

String::camelize =->
  @replace /(^|\-|\_)(\w)/g, (a,b,c)->
    c.toUpperCase()

module.exports =
  activate: (state) ->
    atom.commands.add 'atom-workspace', "rails-open-rspec:open-rspec-file", => @openSpec()

  openSpec: ->
    sourceEditor = atom.workspace.getActiveTextEditor()
    return if !sourceEditor

    currentFilepath = sourceEditor.getPath()
    openFilePath = @findFilepath(currentFilepath)

    return if openFilePath == null
    @openWithWrite(openFilePath, sourceEditor)

  findFilepath: (currentFilepath) ->
    relativePath = currentFilepath.substring(RAILS_ROOT.length)

    if @isSpecFile(relativePath)
      openFilePath = relativePath.replace /\_spec\.rb$/, '.rb'
      openFilePath = openFilePath.replace /^\/spec\//, "/app/"
    else
      openFilePath = relativePath.replace /\.rb$/, '_spec.rb'
      openFilePath = openFilePath.replace /^\/app\//, "/spec/"

    if relativePath == openFilePath
      null
    else
      Path.join RAILS_ROOT, openFilePath

  isSpecFile: (path) ->
    /_spec\.rb/.test(path)

  isSinglePane: ->
    atom.workspace.getPanes().length == 1

  openWithWrite: (openFilePath, sourceEditor) ->
    openOptions = {}
    if @isSinglePane()
      openOptions = { split: 'right' }
    else
      atom.workspace.activateNextPane()

    promise = atom.workspace.open(openFilePath, openOptions)

    promise.then (specEditor) ->
      if specEditor.isEmpty()
        specWriter = new SpecWriter(specEditor, sourceEditor)
        atom.notifications.addInfo("Generate new spec")
        specWriter.write()
