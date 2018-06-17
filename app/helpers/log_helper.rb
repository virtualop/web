module LogHelper

  def self.redis_to_action_cable
    puts "subscribing to 'vop_log' ..."
    redis = Redis.new
    begin
      redis.subscribe("vop_log") do |on|
        on.message do |channel, message|
          ActionCable.server.broadcast("vop_log", message)
        end
      end
    ensure
      redis.unsubscribe("vop_log")
    end
  end

end
