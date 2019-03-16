class ScanChannel < ApplicationCable::Channel

  def subscribed
    logger.info "subscribed to scan updates for #{params[:machine]}"
    stream_from "scan_#{params[:machine]}"
  end

  def unsubscribed
    stop_all_streams
  end

end
