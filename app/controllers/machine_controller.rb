class MachineController < ApplicationController
  def index
    @machines = $vop.list_machines
  end

  def show
    @machine = $vop.machine(params[:name])

    if params[:view] == "pods"
      @pods = @machine.list_pods
      render params[:view]
    elsif params[:view] == "services"
      @services = @machine.list_services
      render :services
    end

  end
end
