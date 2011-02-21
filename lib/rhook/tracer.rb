require "pp"

module RHook
  TRACER_CALLER_RANGE_DEFAULT = [4, 5]
  
  def self.tracer_impl(opt = {})
    require "pp"
    tag = opt[:tag] || "trace"
    caller_range = opt[:caller_range] || TRACER_CALLER_RANGE_DEFAULT
    print = lambda do |msg|
      RHook.trace_printer.call(msg.gsub(/^/, "[#{tag}] ")+"\n")
    end
    lambda do |inv|
      print.call ">> " + PP.pp({inv.name => [{:self => inv.receiver}, {:args => inv.args}, {:block => inv.block}]}, "", 120)

      caller_to_be_print_count = caller_range[1]
      caller(caller_range[0]).each do |location|
        /rhook\.rb/ =~ location and next   # skip rhook method's call.
        (caller_to_be_print_count -= 1) == 0 and break
        print.call "    from #{location}"
      end
      
      begin
        inv.call
      rescue Exception
        print.call("#{$!.message} (#{$!.class})\n" << $!.backtrace.join("\n").gsub(/^/, "  from "))
        raise
      end
      print.call "<< " + PP.pp({inv.name => [{:returned => inv.returned}]}, "", 120)
      inv.returned
    end
  end
end