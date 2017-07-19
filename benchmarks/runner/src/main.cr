BIN_PATH = File.expand_path("../../../bin", __FILE__)

Dir.glob(File.join(BIN_PATH, "*")) do |bin|
  filename = File.basename(bin)
  next unless filename.includes?("bm_")

  costs = test { `#{bin}` }
  min = costs.min
  max = costs.max

  puts filename + " average cost " + ms(average(costs)) + "ms" + ", min " + ms(min) + "s, max " + ms(max) + "s"
end

def test(time = 10, &block)
  times = [] of Float64

  time.times.each do |i|
    s = Time.now
    yield
    e = Time.now

    times.push((e - s).to_f)
  end

  times
end


def ms(time)
  (time * 1000).round(6).to_s
end

def average(data : Array(Float64))
  sum = 0
  data.each {|f| sum += f}

  sum / data.size
end
