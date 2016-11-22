
require('coffee-script/register');

var agree = require('agree');
var tools = agree;
tools.doc = require('./src/doc');
tools.testing = require('./src/testing');
tools.analyze = require('./src/analyze');

module.exports = tools;
