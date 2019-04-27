class MemoryUpdateChannel < ApplicationCable::Channel

  def subscribed
    logger.info "subscribed to memory updates for #{params[:machine]}"
    stream_from "memory_updates_#{params[:machine]}"
  end

  def unsubscribed
    stop_all_streams
  end

end
