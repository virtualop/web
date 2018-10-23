class TailChannel < ApplicationCable::Channel

  def initialize(*args)
    super(*args)
  end

  def subscribed
    logger.info "subscribed to tail for #{params[:log]}@#{params[:machine]}"
    $vop.kill_old_tails(machine: params[:machine])
    $vop.tailf_async(machine: params[:machine], file: params[:log], count: 0, sudo: true)
    stream_from "tail_#{params[:machine]}_#{params[:log]}"
  end

  def unsubscribed
    stop_all_streams
  end

end
