class VmInstallationStatus < ApplicationCable::Channel

  def initialize(*args)
    super(*args)
  end

  def subscribed
    stream_from "vm_installation_status_#{params[:machine]}"
  end

  def unsubscribed
    stop_all_streams
  end

end
