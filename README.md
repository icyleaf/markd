# markd

![Status](https://img.shields.io/badge/status-WIP-blue.svg)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/icyleaf/markd/blob/master/LICENSE)
[![Dependency Status](https://shards.rocks/badge/github/icyleaf/markd/status.svg)](https://shards.rocks/github/icyleaf/markd)
[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/markd/master.svg?style=flat)](https://circleci.com/gh/icyleaf/markd)

Yet another markdown parser built for speed, written in [Crystal](https://crystal-lang.org), Compliant to [CommonMark](http://spec.commonmark.org) specification. Copy from [commonmark.js](https://github.com/jgm/commonmark.js).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  markd:
    github: icyleaf/markd
```

## Quick start

```crystal
require "markd"

markdown = <<-MD
# Hello Markd

> Yet another markdown parser built for speed, written in Crystal, Compliant to CommonMark specification.
MD

html = Markd.to_html(markdown)
```

Also here is an options to configure the parse and render.

```crystal
options = Markd::Options.new(smart: true, safe: true)
Markd.to_html(markdown, options)
```

## Options

Name | Type | Default value | Description |
---|---|---|---
time | `Bool` | false | render parse cost time during read source, parse blocks, parse inline.
smart | `Bool` | false |if **true**, straight quotes will be made curly,<br />`--` will be changed to an en dash,<br />`---` will be changed to an em dash, and<br />`...` will be changed to ellipses.
source_pos | `Bool` | false | if **true**, source position information for block-level elements<br />will be rendered in the data-sourcepos attribute (for HTML)
safe | `Bool` | false | if **true**, raw HTML will not be passed through to HTML output (it will be replaced by comments)
gfm | `Bool` | false | **Not support for now**
toc | `Bool` | false | **Not support for now**

## Advanced

If you want use custom renderer, it can!

```crystal

class CustomRenderer < Markd::Renderer

  def strong(node, entering)
  end

  # more methods following in render.
end

options = Markd::Options.new(time: true)
document = Markd::Parser.parse(markdown, options)
renderer = CustomRenderer.new(options)

html = renderer.render(document)
```

## Performance

For now, i have not pass all specs, the result was ran with `--release` flag with `crystal spec` running with Crystal 0.23.0 (2017-06-30) LLVM 4.0.1 on OS X 10.12.5.

Machine information: MacBook Pro (Retina, 15-inch, Mid 2015), 2.2 GHz Intel Core i7, 16 GB 1600 MHz DDR3.

```
$ time ./bin/spec
Run [spec/spec.txt] examples
 1. Tabs (11)
 2. Precedence (1)
 3. Thematic breaks (19)
 4. ATX headings (18)
 5. Setext headings (26)
 6. Indented code blocks (12)
 7. Fenced code blocks (27)
10. Paragraphs (8)
11. Blank lines (1)
12. Block quotes (25)
13. List items (48)
15. Inlines (1)
23. Raw HTML (21)
24. Hard line breaks (15)
25. Soft line breaks (2)
26. Textual content (3)
Total 26 describes and 621 examples
..................................................................
```
./bin/spec  0.02s user 0.01s system 69% cpu 0.038 total
## Roadmap

- [Features](https://github.com/icyleaf/markd/issues/1)
- [Pass CommonMark Specs](https://github.com/icyleaf/markd/issues/3)

## Milestore

- v1.0
  - 100% Compliant to commonmark
- v1.1
  - GFM support

## Contributing

1. Fork it ( https://github.com/icyleaf/markd/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [icyleaf](https://github.com/icyleaf) - creator, maintainer
