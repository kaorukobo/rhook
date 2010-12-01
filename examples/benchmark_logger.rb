require "rubygems"
# $LOAD_PATH.unshift(File.dirname(__FILE__)+"/../lib")
require "rhook"

require "benchmark"
require "logger"

n = 30000
Benchmark.bm(24) do |x|
  logger = Logger.new(open("/dev/null", "w"))
  
  doit = lambda do
    n.times do
      logger.info("msg")
    end
  end
  
  # ========================================================================
  x.report("direct:") do 
    doit.call
  end
  
  # ========================================================================
  hook = Logger._rhook.hack(:add) do |inv|
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
