require "./spec_helper"

# Commonmark spec exapmles
describe_spec("fixtures/spec.txt")

# Smart punctuation exapmles
describe_spec("fixtures/smart_punct.txt", smart: true)

# Regression exapmles
describe_spec("fixtures/regression.txt")
