# Contracts allows specifying pre/post-conditions, class invariants on function, methods and classes.
#
# TODO: a way to declare an interface which can be implemented by multiple function/classes
# TODO: add first-class support for Promises, wrapper for node.js type async callbacks
#
# Documentation
# - add/generate good toString(), for interactive/REPL docs
# - allow to generate API docs including pre,post,classinvariants
#
# Testing
# - allow to verify all pre,post,classinvariants have been triggered
#
# Debugging
# - ability to log failing predicates, including descritpion, location of fail, reason for fail
# - ability to cause failing predicate to cause breakpoint using `debugger` statement
#
# Performance
# - MAYBE: opt-out of postcondition and class invariant checking
#
# Research:
# - Prototype a way to declare and verify symmetrical functions, ie ones which cancel eachother out
# - Sketch out a way to provide default for pre/post/invar, as an executable/verifiable coding-style
# - Allow class invariants be explicit on class, or implicit derived from contract-based properties or both?
# - Investigate how to generate useful documentation, both
# and REPL-like runtime introspection
#  Use positive and negative example as docs/tests for predicate functions
# - Investigate how unit tests can be generated from introspected
# invariants, or how checks can replace unit tests for simple cases
# - Investigate to which extent invariants can be statically checked,
# prototype reasoning about some simple cases.
# http://coffeescript.org/documentation/docs/nodes.html
# http://www.coffeelint.org/
# https://github.com/jashkenas/coffeescript/issues/1466
#
#
# Random/ideas:
# - Should contracts and their use be registered globally, for dependency tracking?
# Could allow tracking whether they are all set up statically or not
#
# References:
#
# - http://c2.com/cgi/wiki?DesignByContract
# - http://disnetdev.com/contracts.coffee/ custom syntax+compiler based on coffee-script
# - http://dlang.org/contracts.html built-in support for contracts in D

agree = {}

# Framework
class ContractFailed extends Error

class PreconditionFailed extends ContractFailed
    constructor: (name, cond) ->
       @message = "#{name}: #{cond?.name}"

class PostconditionFailed extends ContractFailed
    constructor: (name, cond) ->
       @message = "#{name}: #{cond?.name}"

class ClassInvariantViolated extends ContractFailed
    constructor: (name, cond) ->
       @message = "#{name}: #{cond?.name}"

class NotImplemented extends Error
    constructor: () ->
        @message = 'Body function not implemented'

agree.ContractFailed = ContractFailed
agree.PostconditionFailed = PostconditionFailed
agree.ClassInvariantViolated = ClassInvariantViolated

class FunctionContract
    constructor: (@name, @parent, @options) ->
        @postconditions = []
        @preconditions = []
        @func = () ->
            throw new NotImplemented
        defaultOptions =
            checkPrecond: true
            checkClassInvariants: true
            checkPostcond: true
        @options = defaultOptions # FIXME: don't override

    ## Fluent construction
    post: () -> @postcondition.apply @, arguments
    postcondition: (conditions) ->
        conditions = [conditions] if not conditions.length
        for c in conditions
            @postconditions.push c
        return this

    pre: () -> @precondition.apply @, arguments
    precondition: (conditions, onFail) ->
        conditions = [conditions] if not conditions.length
        for c in conditions
            o = { predicate: c }
            o.onFail = onFail if onFail
            @preconditions.push o
        return this

    body: (f) ->
        @func = f
        return this

    # Register as ordinary function on
    add: (context, name) ->
        name = @name if not name?
        call = (instance, args) =>
            @call instance, args, name
        func = () ->
            call this, arguments
        func.contract = this # back-reference for introspection
        context[name] = func
        return this

    # Chain up to parent to continue fluent flow there
    method: () ->
        return @parent.method.apply @parent, arguments if @parent

    # Executing
    call: (instance, args, name) ->
        options = @options

        if options.checkClassInvariants and instance.contract?
            for invariant in instance.contract.invariants
                pass = invariant.apply instance
                throw new ClassInvariantViolated if not pass
        if options.checkPrecond
            for cond in @preconditions
                preconditionPassed = cond.predicate.apply instance, args
                if not preconditionPassed
                    if cond.onFail
                        return cond.onFail()
                    else
                        throw new PreconditionFailed @name, cond

        ret = @func.apply instance, args

        if options.checkPostcond
            for cond in @postconditions
                throw new PostconditionFailed @name, cond if not cond.apply instance, args
        if options.checkClassInvariants and instance.contract?
            for invariant in instance.contract.invariants
                pass = invariant.apply instance
                throw new ClassInvariantViolated if not pass

        return ret

    getClass: () ->
        return @parent?.getClass()

agree.function = (name, parent, options) ->
    return new FunctionContract name, parent, options

class ClassContract
    constructor: (@name, @options) ->
        @invariants = []
        @initializer = () ->
            # console.log 'ClassContract default initializer'

        self = this
        construct = (instance, args) =>
            @construct instance, args
        @klass = () ->
            this.contract = self # back-reference for introspection
            construct this, arguments
        @klass.contract = this # back-reference for introspection

        defaultOptions =
            checkPrecond: true
            checkClassInvariants: true
            checkPostcond: true
        @options = defaultOptions # FIXME: don't override

    # add a method
    method: (name) ->
        f = agree.function "#{@name}.#{name}", this
        return f.add @klass.prototype, name

    # add constructor
    init: (f) ->
        @initializer = f
        return this

    # add class invariant
    invariant: (conditions) ->
        conditions = [conditions] if not conditions.length
        for cond in conditions
            @invariants.push cond
        return this

    # register ordinary constructor
    add: (context, name) ->
        name = @name if not name
        context[name] = @klass
        return this

    construct: (instance, args) ->
        @initializer.apply instance, args

        # Check class invariants
        if @options.checkClassInvariants
            for invariant in instance.contract?.invariants
                throw new ClassInvariantViolated if not invariant.apply instance
        return instance

    getClass: ->
        return @klass

agree.Class = (name) ->
    return new ClassContract name

module.exports = agree

