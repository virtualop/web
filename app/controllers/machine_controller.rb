class MachineController < ApplicationController
  def index
    @machines = $vop.list_machines.sort_by { |machine| machine["name"] }
  end

  def show
    @machine = $vop.machine(params[:name])
    @reachable = $vop.test_ssh("machine" => params[:name])

    return unless @reachable

    begin
      @vms = @machine.list_vms.sort_by { |row| [ row[:name] ].join(":") }
    rescue
      $logger.warn "could not render VMs in machine view for #{params[:name]}"
    end

    @services = @machine.list_services.sort_by { |row| row[:name] }

    if params[:view] == "pods"
      @pods = @machine.list_pods
      render params[:view]
    elsif params[:view] == "kube_services"
      # TODO in a better world, this would not be called @services
      @services = @machine.list_services
      render :services
    end
  end

  def map
    @map = $vop.list_all_hosts.map do |row|
      row["vms"] = $vop.list_vms("machine" => row["name"])
      row
    end
  end

end
