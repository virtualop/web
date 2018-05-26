require "redis"

class VopLogChannel < ApplicationCable::Channel

  def initialize(*args)
    super(*args)
    @redis = Redis.new
  end

  def subscribed
    puts "subscribed for vop_log"
    stream_from "vop_log"

    @redis.subscribe("vop_log") do |on|
      on.message do |channel, message|
        ActionCable.server.broadcast("vop_log", message)
      end

    end
  end

end
