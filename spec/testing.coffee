
chai = require 'chai'
agree = require '../'
utils = require './utils'

agreeTest = (modulePath, callback) ->
  child_process = require 'child_process'
  prog = utils.projectPath "./bin/agree-test"
  args = [
    modulePath
  ]
  options = {}
  child_process.execFile prog, args, options, callback

findPasses = (str) ->
  return str.match /^.*: PASS$/mg
findFails = (str) ->
  m = str.match /^.*: Error:.*$/mg
  m = [] if not m?
  return m

describe 'agree-test', ->

  describe 'on HTTP server example', ->
    example = utils.agreePath 'examples/httpserver.coffee'
    stdout = ""
    stderr = ""

    describe 'when passing all tests', ->

      it 'exitcode is 0', (done) ->
        agreeTest example, (err, sout, serr) ->
          stdout = sout
          stderr = serr
          chai.expect(err).to.not.exist
          return done err
      it 'stdout includes passing tests', () ->
        chai.expect(stdout).to.contain 'GET /somedata'
        passes = findPasses(stdout)
        chai.expect(passes).to.have.length.above 3
      it 'stdout has no failing tests', () ->
        fails = findFails(stdout)
        chai.expect(fails, fails).to.have.length 0

    describe 'when injecting faults', -> # TODO: implement
      it 'exitcode is non-zero'
      it 'stdout lists failures'
      it 'stdout shows failure details'
