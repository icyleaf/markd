var fs = require('fs');
var commonmark = require('commonmark');

var reader = new commonmark.Parser();
var writer = new commonmark.HtmlRenderer();
var file = fs.readFileSync('../../source.md', 'utf8');
var doc = reader.parse(file);
var rendered = writer.render(doc);
