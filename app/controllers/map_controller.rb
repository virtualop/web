class MapController < ApplicationController

  def index
  end

  def accounts
    @accounts = $vop.hetzner_accounts
  end

  def account
    host_names = $vop.hetzner_server_list(params[:account]).map { |x| x["name"] }
    (@hosts, @host_vms) = helpers.vms_for_host_names(host_names)
  end

  def group
    @name = "dev"
    host_names = %w|santafe.xop cabildo.traederphi|

    @host_vms = {}
    @hosts = []
    host_names.each do |host_name|
      @host_vms[host_name] = helpers.host_data(host_name)
      @hosts << $vop.machines[host_name]
    end

    puts "hosts : #{@hosts.map(&:name)}"
    puts "host_vms : #{@host_vms.pretty_inspect}"
  end

  def host
    @host = $vop.machines[params[:machine]]
    @vms = helpers.host_data()
  end

end
