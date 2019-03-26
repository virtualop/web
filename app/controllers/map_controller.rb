class MapController < ApplicationController

  def index
    @page_title = "map"
    @accounts = {}
    $vop.hetzner_accounts.each do |account|
      $logger.info "fetching data for account #{account.alias}"

      host_names = account.hetzner_server_list.map { |x| x["name"] }
      @accounts[account] = helpers.vms_for_host_names(host_names)
    end
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
  end

  def host
    @host = $vop.machines[params[:machine]]
    @page_title = "map #{@host.name}"
    @vms = helpers.host_data()
  end

  def host_box
    host

    render partial: "host", locals: {
      host: @host,
      vms: @vms
    }
  end

  # --

  def delete
    $logger.info "deleting machine #{params[:machine]}"
    machine = $vop.machines[params[:machine]]
    @host = machine.parent

    machine.delete_machine

    @vms = helpers.host_data(@host.name)

    render partial: "host", locals: {
      host: @host,
      vms: @vms
    }
  end

end
