
exports.projectPath = (p) ->
  path = require 'path'
  return path.join __dirname, '..', p
exports.agreePath = (p) ->
  path = require 'path'
  return path.join __dirname, '..', 'node_modules', 'agree', p
