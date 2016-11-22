[![Build Status](https://travis-ci.org/jonnor/agree-tools.svg?branch=master)](https://travis-ci.org/jonnor/agree-tools)
# Agree: Contract programming for JavaScript

[Agree](http://agreejs.org) is a library for implementing Contract Programming / 
[Design by contract](http://en.wikipedia.org/wiki/Design_by_contract) in JavaScript,
including `preconditions`, `postconditions` and `class invariants`.

This repository contains the developer tools that come with Agree.
For general information about the library, go to [jonnor/agree](https://github.com/jonnor/agree).

## Installing

    npm install --save-dev agree-tools

## Tools

`agree-doc` can introspect modules and generate plain-text documentation.

`agree-test` can introspect modules, extract examples from contracts,
and automatically generate and run tests from these.

`agree-analyze` can introspect an agree.Chain and its contracts,
and demonstrate bugs in their composition.

## License

MIT, see [LICENSE.md](./LICENSE.md)

