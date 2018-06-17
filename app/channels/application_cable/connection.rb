module ApplicationCable
  class Connection < ActionCable::Connection::Base

    identified_by :uuid

    def connect
      self.uuid = SecureRandom.urlsafe_base64
    end

    def disconnect
      logger.debug "disconnecting"
      logger.debug "uuid : #{uuid}"
    end

  end
end
