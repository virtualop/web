class MachinesController < ApplicationController

  def index
    @machines = $vop.machines.sort_by(&:name)
  end

  def show
    @machine = $vop.machines[params[:machine]]
    @ssh_status = @machine.test_ssh

    @scan = @machine.scan_result

    services_data

    if @services && @services.include?("apache.apache")
      @domains = @machine.vhosts.select do |vhost|
        ! vhost["domain"].nil?
      end
    else
      @domains = []
    end
  end

  def services_data
    @machine = $vop.machines[params[:machine]]
    @services = @machine.detect_services.sort
    @installables = $vop.services
      .sort_by { |x| x.name }
      #.delete_if { |x| @services && @services.include?(x.name) }
  end

  def services
    services_data

    render partial: "services"
  end

  def new
    $logger.info "new machine #{params[:vm_name]} on #{params[:host_name]}"

    p = {
      "machine" => params[:host_name],
      "name" => params[:vm_name]
    }
    if params[:memory]
      p[:memory] = params[:memory]
    end
    request = ::Vop::Request.new $vop, "new_machine", p
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

  def service_params
    service = $vop.services.select { |x| x.name == params[:service] }.first

    render json: service.data["params"].to_json()
  end

  def install_service
    service = $vop.services.select { |x| x.name == params[:service] }.first
    puts "installing service #{params[:service]} on #{params[:machine]}"

    # pass on all params except these
    blacklist = %w|authenticity_token controller action|
    p = {}
    params.each do |k,v|
      unless blacklist.include? k
        p[k] = v
      end
    end

    $vop.install_service_async(p)
  end

  def scan
    $vop.inspect_async(params[:machine]).to_json
    render json: {status: "scan has been scheduled"}.to_json
  end

end
