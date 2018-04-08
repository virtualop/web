class MachinesController < ApplicationController

  def index
    #@machines = $vop.machines.sort_by { |x| x.name }
    begin
      @machines = Machine.all.sort_by { |x| x.name }
    rescue
      render text: "found a machine without a name."
      @machines = Machine.all
    end
    @status = {}
    @ssh_status = {}
    @metadata = {}
    @machines.each do |machine|
      test_request = Vop::Request.new($vop, "test_ssh", {"machine" => machine.name})
      begin
        @ssh_status[machine.name] = $vop.execute_request(test_request)
      rescue => e
        response = ::Vop::Response.new(e.message, {})
        response.status = "error"
        @ssh_status[machine.name] = response
      end

      @metadata[machine.name] = $vop.metadata(machine.name)
    end
  end

  def delete_record
    puts "delete machine record #{params[:machine]}"
    $vop.clean_metadata(params[:machine])
    Machine.find_by_name(params[:machine]).delete
    render text: "deleted machine record #{params[:machine]}"
  end

  def new_vm
    NewVmWorker.perform_async(params[:machine], params[:vm_name])

    sleep 2

    $vop.machines[params[:machine]].list_vms!

    render text: "new machine installation has been started."

    # $vop.invalidate_cache("command" => "list_vms", "raw_params" => {"machine" => host_name})
    # $vop.invalidate_cache("command" => "processes", "raw_params" => {"machine" => host_name})
    # $vop.invalidate_cache("command" => "vnc_ports", "raw_params" => {"machine" => host_name})
  end

  def delete_vm
    host_name = params[:machine]
    puts "deleting vm #{params[:name]} on host #{host_name}"

    $vop.delete_vm(machine: params[:machine], name: params[:name])
    render text: "deleted #{params[:name]} on #{params[:machine]}"
  end

  def installation_status_data(host_name, vm_name)
    installation = Installation.where(host_name: host_name, vm_name: vm_name).first
    sidekiq_worker = $vop.running_installation(host_name: host_name, vm_name: vm_name).first
    [ installation, sidekiq_worker ]
  end

  def installation_status
    (@installation, @sidekiq_worker) = installation_status_data(params[:machine], params[:vm])

    render json: {
      record: @installation,
      sidekiq: @sidekiq_worker
    }.to_json
  end

  def map
    @vms = {}
    @hosts = $vop.machines.select do |machine|
      machine.metadata["type"] == "host"
    end.each do |host|
      sorted_vms = $vop.list_vms(host.name).sort_by { |row| row["name"] }
      sorted_vms.each do |vm|
        vm["full_name"] = "#{vm["name"]}.#{host.name}"
        vm["readable_state"] = vm["state"].tr(" ", "_")
      end

      # add information about running installations
      sorted_vms.each do |vm|
        (vm["installation"], vm["sidekiq"]) = installation_status_data(host.name, vm["name"])
      end

      # detect services on VMs
      sorted_vms.each do |vm|
        detected = []
        begin
          next unless $vop.test_ssh(vm["full_name"])
          detected = $vop.detect_services(vm["full_name"])
        rescue => detail
          $logger.warn("error trying to detect services for #{vm["full_name"]} : #{detail.message}")
        end
        vm["services"] = detected
      end

      # detect domains through reverse proxy and store them by VM
      begin
        host.vms_with_domains.each do |proxy|
          if proxy.data.has_key?("proxy") && proxy.data["proxy"].has_key?("hostname")
            vm_name = proxy.data["proxy"]["hostname"]
            host.data["domains"] ||= Hash.new { |h,k| h[k] = [] }
            host.data["domains"][vm_name] << proxy.data["domain"]
          end
        end
      rescue => e
        $logger.warn "could not list reverse proxies for #{host.name} : #{e.message}"
      end

      @vms[host.name] = sorted_vms
    end
  end

  def service_icon
    puts "showing icon for service #{params[:service]}"

    service = $vop.services.select { |x| x.name == params[:service] }.first

    icon_path = File.join(service.plugin.plugin_dir("files"), service.data[:icon])

    #service = $vop.list_known_services.select { |x| x["name"] == params[:service] }.first
    #icon_path = service[:icon]

    puts "icon path : #{icon_path}"

    if icon_path
      send_data open(icon_path, "rb") { |f| f.read }
    else
      send_data open("#{Rails.root}/public/blank.png", "rb") { |f| f.read }
    end
  end

  def show
    puts "showing machine #{params[:machine]}"
    @machine = $vop.machines[params[:machine]]

    begin
      test_request = Vop::Request.new($vop, "test_ssh", {"machine" => @machine.name})
      @ssh_status = $vop.execute_request(test_request)
      puts "ssh status : #{@ssh_status.result}"
    rescue => e
      puts "error testing ssh connect : #{e.message}"
      if e.message =~ /no SSH options/
        @ssh_error = "no_ssh_options"
      else
        @ssh_error = e.message
      end
    end

    if @ssh_status
      begin
        @distro = @machine.distro

        @internal_ip = nil
        begin
          @internal_ip = @machine.internal_ip
        rescue => e
          puts "problem reading internal IP from #{params[:machine]} : #{e.message}"
        end

        @services = @machine.detect_services

        if @services.include?("apache.apache")
          @vhosts = []
          begin
            @vhosts = @machine.vhosts.select { |v| v["enabled"] }
            pp @vhosts
          rescue => e
            puts "could not load vhosts : #{e.message}"
          end

          begin
            @access_log = @machine.tail_access_log(count: 25)
          rescue => e
            puts "could not load access log : #{e.message}"
          end
        end

        if @distro.split("_").first == "centos"
          begin
            @packages = @machine.list_rpm_packages
          rescue => e
            puts "could not load package list : #{e.message}"
          end
        end
      rescue => e
        puts "problem loading machine information : #{e.message}"
      end
    end
  end

  def show_multi
    logger.info "showing multiple machines : #{params[:machine]}"


  end

end
