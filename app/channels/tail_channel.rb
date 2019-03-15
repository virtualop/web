class TailChannel < ApplicationCable::Channel

  def initialize(*args)
    super(*args)
  end

  def subscribed
    logger.info "subscribed to tail for #{params[:log]}@#{params[:machine]}"
    $vop.kill_old_tails(machine: params[:machine], file: params[:log])

    if params[:style] && params[:style] == "new"
      $vop.keep_tailing_async(machine: params[:machine], file: params[:log], count: 0, sudo: true)
    else
      $vop.tailf_async(machine: params[:machine], file: params[:log], count: 0, sudo: true)
    end
    stream_from "tail_#{params[:machine]}_#{params[:log]}"
  end

  def unsubscribed
    stop_all_streams
  end

end
