require "./spec_helper"

examples = extract_spec_tests("spec/spec.txt")
examples.each do |section, tests|
  assert_section(section, tests)
end
