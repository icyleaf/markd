# markd

![Version](https://img.shields.io/badge/version-1.0-blue.svg)
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

First of all, Markd is slower than [Crystal Built-in Markdown](https://crystal-lang.org/api/0.23.0/Markdown.html) which it is a lite version, only apply for generte Cystal documents ([#4613](https://github.com/crystal-lang/crystal/issues/4613)).

Here is the result of readme parse at MacBook Pro Retina 2015 (2.2 GHz):

```
Crystal Built-in 211.67k (  4.72µs) (± 2.53%)       fastest
           Markd   8.65k (115.58µs) (± 7.49%) 24.47× slower
```

Recently, i'm working to compare the other popular commonmark parser, the code is stored in [benchmarks](/benchmarks).

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
