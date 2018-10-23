module LogHelper

  class MessagePump

    attr_reader :redis, :queue

    def initialize(queue)
      @redis = Redis.new
      @queue = queue
    end

    def channel_name(message_json = nil)
      if queue == "installation_status" || queue == "vm_installation_status"
        message = JSON.parse(message_json)
        "#{queue}_#{message["machine"]}"
      elsif queue == "tail" || queue == "graph"
        message = JSON.parse(message_json)
        "#{queue}_#{message["machine"]}_#{message["log"]}"
      else
        queue
      end
    end

    def redis_to_action_cable
      puts "subscribing to '#{queue}' ..."
      redis.subscribe(queue) do |on|
        on.message do |channel, message|
          ActionCable.server.broadcast(channel_name(message), message)
        end
      end
    end

  end

  def self.watch(queue)
    thread = Thread.new do
      MessagePump.new(queue).redis_to_action_cable
    end
  end

  def self.message_pump
    threads = %w|vop_log installation_status vm_installation_status tail graph|.map do |queue|
      self.watch queue
    end
    threads.each do |thread|
      thread.join
    end
  end

end
