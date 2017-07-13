require "spec"
require "../src/markd"

def describe_spec(file)
  specs = extract_spec_tests(file)

  puts "Run [#{file}] examples"
  specs_count = 0
  examples_count = 0
  specs.each do |section, examples|
    specs_count += 1
    examples_count += examples.size
    puts "#{specs_count.to_s.rjust(2)}. #{section} (#{examples.size})"
  end
  puts "Total #{specs_count} describes and #{examples_count} examples"

  specs.each_with_index do |(section, examples), index|
    next if index == 7 || index == 8
    exit if index == 10
    assert_section(file, section, examples)
  end
end

def assert_section(file, section, examples)
  describe section do
    examples.each do |index, example|
      assert_exapmle(file, section, index, example)
    end
  end
end

def assert_exapmle(file, section, index, example)
  markdown = example["markdown"].gsub("→", "\t").chomp
  html = example["html"].gsub("→", "\t")
  line = example["line"].to_i

  it "- #{index}\n#{show_space(markdown)}", file, line do
    output = Markd.to_html(markdown)
    output.should eq(html), file, line
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
    line_number = 0
    while line = f.read_line
      line_number += 1
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
            "line" => line_number.to_s,
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

  # Remove empty examples
  examples.keys.each {|k| examples.delete(k) if examples[k].empty? }
  examples
end

def show_space(text)
  text.gsub("\t", "→").gsub(/ /, '␣')
end
