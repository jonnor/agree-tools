## Convenience stuff around Express.JS
# Will eventually be moved into its own library

agree = require('./agree')

conditions = {}
conditions.requestContentType = (type) ->
  check = (req, res) ->
    actual = req.get 'Content-Type'
    err = if actual != type then new Error "Request must have Content-Type: '#{type}', got '#{actual}'" else null
    return err

  return new agree.Condition check, "Request must have Content-Type '#{type}'", { 'content-type': type }

# TODO: move schema things to separate file ./schema.coffee
# TODO: allow to infer schema from an example object
# MAYBE: combine inferred schema, with class-invariant,
#    to ensure all properties are declared in constructor with defaults?
#    if used as pre-condition on other functions, basically equivalent to a traditional class type!
validateSchema = (data, schema, options) ->
    tv4 = require 'tv4'
    result = tv4.validateMultiple data, schema, !options.allowUnknown
    #console.log 'd', data, result
    if result.valid
      return null
    else
      message = []
      for e in result.errors
        message.push "#{e.message} for path '#{e.dataPath}'"
      return new Error message.join('\n')

# TODO: let take schema id as input
# TODO: set schema url if not set
#    '$schema': 'http://json-schema.org/draft-04/schema'
# TODO: allow referencing named schemas
conditions.requestSchema = (schema, options = {}) ->
  options.allowUnknown = false if not options.allowUnknown
  schemaDescription = schema.id
  schemaDescription = schema if not schemaDescription?

  check = (req, res) ->
    return validateSchema req.body, schema, options

  return new agree.Condition check, "Request body must follow schema '#{schemaDescription}'", { jsonSchema: schema }

conditions.responseStatus = (code) ->
  check = (req, res) ->
    actual = res.statusCode
    err = if actual != code then new Error "Response did not have statusCode '#{code}', instead '#{actual}'" else null
    return err

  c = new agree.Condition check, "Response has statusCode '#{code}'", { 'statusCode': code }
  c.target = 'arguments'
  return c

# TODO: treat as special case of responseHeaderMatches ?
conditions.responseHeaderMatches = (header, regexp) ->
  check = (req, res) ->
    regexp = new RegExp regexp if typeof regexp == 'string'
    actual = res._headers[header.toLowerCase()]
    err = if actual? and regexp.test actual then null else new Error "Response header '#{header}':'#{actual}' did not match '#{regexp}'"
    return err

  c = new agree.Condition check, "Response header '#{header}' matches '#{regexp}'", { header: header, regexp: regexp }
  c.target = 'arguments'
  return c

conditions.responseContentType = (type) ->
  check = (req, res) ->
    header = res._headers['content-type']
    actual = header?.split(';')[0]
    err = if actual != type then new Error "Response has wrong Content-Type. Expected '#{type}', got '#{actual}'" else null
    return err

  c = new agree.Condition check, "Response has Content-Type '#{type}'", { 'content-type': type }
  c.target = 'arguments'
  return c

checkResponseEnded = (req, res) ->
  return if not res.finished then new Error 'Response was not finished' else null
conditions.responseEnded = new agree.Condition checkResponseEnded, "Reponse is sent"
conditions.responseEnded.target = 'arguments'

# TODO: take if as optional first param
conditions.responseSchema = (schema, options = {}) ->
  options.allowUnknown = false if not options.allowUnknown
  schemaDescription = schema.id
  schemaDescription = schema if not schemaDescription?
  check = (req, res) ->
    return validateSchema res._jsonData, schema, options
  c = new agree.Condition check, "Response body follows schema '#{schemaDescription}'", { jsonSchema: schema }
  c.target = 'arguments'
  return c

exports.installExpressRoutes = (app, routes) ->
  for name, route of routes
    contract = agree.getContract route
    method = contract.attributes.http_method?.toLowerCase()
    path = contract.attributes.http_path
    if method and path
      app[method] path, route
    else
      console.log "WARN: Contract '#{contract.name}' missing HTTP method/path"

exports.mockingMiddleware = (req, res, next) ->
  # attaches data sent with json() function
  original = res.json
  res.json = (obj) ->
    res._jsonData = obj
    original.apply res, [obj]
  next()

exports.requestFail = (i, args, failures, reason) ->
  [req, res] = args
  res.status 422
  errors = failures.map (f) -> { condition: f.condition.name, message: f.error.toString() }
  res.json { errors: errors }

class Tester
    constructor: (@app) ->
      @port = process.env.PORT or 3334
      @host = process.env.HOST or 'localhost'
      @server = null
    setup: (callback) ->
      return @server = @app.listen @port, callback
    teardown: (callback) ->
      @server.close() if @server
      return callback null
    run: (thing, contract, example, callback) ->
      http = require 'http'
      method = contract.attributes.http_method
      path = example.path or contract.attributes.http_path
      test = example.payload
      r =
        host: @host
        port: @port
        method: method
        path: path
      r.headers = test.headers if test.headers?
      req = http.request r
      responseBody = ""
      req.on 'response', (res) ->
        res.on 'data', (chunk) ->
          responseBody += chunk.toString 'utf-8'
        res.on 'end', () ->
          checks = []
          if test.responseCode?
            if test.responseCode != res.statusCode
              err = new Error "Wrong response status. Expected #{test.responseCode}, got #{res.statusCode}"
            checks.push { name: 'responseStatusCode', error: err} 
          return callback null, checks
      req.on 'error', (err) ->
        console.log 'request error', err
        return if not callback
        callback err
        return callback = null
      req.end()
exports.Tester = Tester

exports.conditions = conditions
