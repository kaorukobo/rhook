require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "rhook examples" do
  describe "log buffer (hack Logger)" do
    require "logger"
    
    # Captures any messages written to Logger and keep in buffer.
    # You can read captured messages by LogBuffer#get 
    # or LogBuffer##pull ( also clears buffer ). 
    class LogBuffer
      def initialize
        @buf = ""
        # Any log messages are passed to Logger#format_message. Hack it!!
        Logger._rhook.hack(:format_message) do |inv|
          result = inv.call
          @buf << result
          result
        end
      end
      
      def clear
        @buf = ""
      end
      
      def get
        @buf
      end
      
      def pull
        result = get()
        clear()
        result
      end
    end #/LogBuffer
    
    # The example application to test.
    # You cannot know whether it success or failed, (by return value or exception)
    # ... it only logs.
    class TargetApp
      def initialize
        @log = Logger.new(STDERR)
      end
      
      def success
        @log.info "Success!"
      end
      
      def fail
        @log.error "Failed!"
      end
    end
    
    example "Use LogBuffer to write test" do
      app = TargetApp.new
      
      # start to capture log.
      logbuf = LogBuffer.new
      
      app.success
      logbuf.pull.should match(/Success!/)
      
      app.fail
      logbuf.pull.should match(/Failed!/)
    end
  end
end