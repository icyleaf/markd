require "tartrazine"
require "../../src/markd"

markdown = <<-MD
  # Hello Markd

  > Yet another markdown parser built for speed, written in Crystal, Compliant to CommonMark specification.
  MD

Markd.to_html(markdown)
