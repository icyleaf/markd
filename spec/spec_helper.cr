require "spec"
require "../src/markd"

def describe_spec(file)
  examples = extract_spec_tests(file)
  examples.each do |section, tests|
    assert_section(section, tests)
  end
end

def assert_section(section, tests)
  describe section do
    tests.each do |index, test|
      assert_test(index, test)

      exit if index == 12
    end
  end
end

def assert_test(index, test)
  markdown = test["markdown"].gsub("→", "\t")
  html = test["html"].gsub("→", "\t")

  it "- #{index}\n#{show_space(markdown)}" do
    output = Markd.to_html(markdown)
    output.should eq html
  end
end

def extract_spec_tests(file)
  data = [] of String
  delimiter = "`" * 32

  examples = {} of String => Hash(Int32, Hash(String, String))

  current_section = 0
  example_count = 0
  test_start = false
  result_start = false

  File.open(file) do |f|
    while line = f.read_line
      line = line.gsub(/\r\n?/, "\n")
      break if line.includes?("<!-- END TESTS -->")

      if !test_start && !result_start && (match = line.match(/^\#{1,6}\s+(.*)$/))
        current_section = match[1]
        examples[current_section] = {} of Int32 => Hash(String, String)
        example_count = 0
      else
        if !test_start && !result_start && line =~ /^`{32} example$/
          test_start = true
        elsif test_start && !result_start && line =~ /^\.$/
          test_start = false
          result_start = true
        elsif !test_start && result_start && line =~ /^`{32}/
          result_start = false
          example_count += 1
        elsif test_start && !result_start
          examples[current_section][example_count] ||= {
            "markdown" => "",
            "html" => ""
          } of String => String

          examples[current_section][example_count]["markdown"] += line + "\n"
        elsif !test_start && result_start
          examples[current_section][example_count]["html"] += line + "\n"
        end
      end
    end
  end

  examples
end

def show_space(text)
  text.gsub("\t", "→").gsub(/ /, '␣')
end
