class MachinesController < ApplicationController

  def index
    @machines = $vop.machines.sort_by(&:name)
  end

  def show
    @machine = $vop.machines[params[:machine]]
    @ssh_status = @machine.test_ssh

    @scan = @machine.scan_result
    @services = @scan["services"]

    if @services && @services.include?("apache.apache")
      @domains = @machine.vhosts.select do |vhost|
        ! vhost["domain"].nil?
      end
    else
      @domains = []
    end
  end

  def new
    $logger.info "new machine #{params[:vm_name]} on #{params[:host_name]}"

    request = ::Vop::Request.new $vop, "new_machine",
      {"machine" => params[:host_name], "name" => params[:vm_name]}
    $vop.execute_async(request)
  end

  def delete
  end

  def service_icon
    service = $vop.services.select { |x| x.name == params[:service] }.first
    icon_path = File.join(service.plugin.plugin_dir("files"), service.data[:icon])

    if icon_path
      send_data open(icon_path, "rb") { |f| f.read }
    else
      send_data open("#{Rails.root}/public/blank.png", "rb") { |f| f.read }
    end
  end

  def scan
    $vop.inspect_async(params[:machine]).to_json
    render json: {status: "scan has been scheduled"}.to_json
  end

end
