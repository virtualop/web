class TailChannel < ApplicationCable::Channel

  def initialize(*args)
    super(*args)
  end

  def subscribed
    logger.info "subscribed to tail for #{params[:log]}@#{params[:machine]}"
    # TODO stop tailing at some point
    $vop.tailf_async(machine: params[:machine], file: params[:log], sudo: true)
    stream_from "tail_#{params[:machine]}_#{params[:log]}"
  end

  def unsubscribed
    stop_all_streams
  end

end
