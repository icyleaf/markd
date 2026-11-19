require "../fixtures/tartrazine"

formatter = Tartrazine::Html.new
expected = formatter.format("x <- 1", Tartrazine.lexer("r"))

%w[r language-r].each do |language|
  actual = Markd.to_html("```#{language}\nx <- 1\n```", formatter: formatter)
  raise "Expected Tartrazine to highlight #{language} as R" unless actual.strip == expected.strip
end
