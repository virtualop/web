class InstallationStatus < ApplicationCable::Channel

  def initialize(*args)
    super(*args)
  end

  def subscribed
    stream_from "installation_status_#{params[:machine]}"
  end

  def unsubscribed
    stop_all_streams
  end

end
