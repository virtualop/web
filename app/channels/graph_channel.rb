class GraphChannel < ApplicationCable::Channel

  def subscribed
    logger.info "subscribed to graph for #{params[:log]}@#{params[:machine]}"
    stream_from "graph_#{params[:machine]}_#{params[:log]}"
  end

  def unsubscribed
    stop_all_streams
  end

end
