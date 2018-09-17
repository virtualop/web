$vop = Vop.setup

domain_root = ENV.fetch("VOP_DOMAIN") {
  $logger.debug "no vop domain configured"
  nil
}
unless domain_root.nil?
  cable_domain = ENV.fetch("VOP_DOMAIN_CABLE") { "cable.#{domain_root}" }

  $logger.info "vop domain : #{domain_root}"
  $logger.info "cable domain : #{cable_domain}"

  Rails.application.configure do
    config.action_cable.url = "ws://#{cable_domain}"
    config.action_cable.allowed_request_origins = [ /http:\/\/#{domain_root}.*/ ]
  end
end
