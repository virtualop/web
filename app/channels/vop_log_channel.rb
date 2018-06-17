require "redis"

class VopLogChannel < ApplicationCable::Channel

  def initialize(*args)
    super(*args)
  end

  def subscribed
    stream_from "vop_log"
  end

  def unsubscribed
    stop_all_streams
  end

end
