require "rubygems"
# $LOAD_PATH.unshift(File.dirname(__FILE__)+"/../lib")
require "rhook"

require "benchmark"

class Target
  def target

  end
end

n = 30000
Benchmark.bm(24) do |x|
  t = Target.new
  
  doit = lambda do
    n.times do
      t.target
    end
  end
  
  # ========================================================================
  x.report("direct:") do 
    doit.call
  end
  
  # ========================================================================
  hook = Target._rhook.hack(:target) do |inv|
    inv.call
  end
  
  x.report("rhook enabled:") do 
    doit.call
  end
  
  # ========================================================================
  hook.disable
  
  x.report("rhook disabled:") do 
    doit.call
  end
end
