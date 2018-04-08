class MapController < ApplicationController

  def index
    host_names = $vop.machines.select { |x| x.metadata["type"] == "host" }.map &:name

    @host_vms = {}
    @hosts = []
    host_names.each do |host_name|
      @host_vms[host_name] = host_data(host_name)
      @hosts << $vop.machines[host_name]
    end
  end

  def account
  end

  def group
    @name = "dev"
    host_names = %w|santafe.xop cabildo.traederphi|

    @host_vms = {}
    @hosts = []
    host_names.each do |host_name|
      @host_vms[host_name] = host_data(host_name)
      @hosts << $vop.machines[host_name]
    end

    puts "hosts : #{@hosts.map(&:name)}"
    puts "host_vms : #{@host_vms.pretty_inspect}"
  end

  def new_vm
    request = ::Vop::Request.new($vop, "new_machine", {"machine" => params[:machine], "name" => params[:vm_name]})
    $vop.execute_async(request)

    sleep 2

    $vop.machines[params[:machine]].list_vms!

    render text: "new machine installation has been started."
  end

  def host
    @host = $vop.machines[params[:machine]]
    @vms = host_data
  end

  def host_data(host_name = params[:machine])
    host = $vop.machines[host_name]
    logger.info "host map : #{host.name}"

    vms_with_domains = []
    begin
      vms_with_domains = host.vms_with_domains
    rescue => e
      $logger.warn "cannot load vms_with_domains : #{e.message}"
    end
    installations = Installation.where(host_name: host_name)

    vms = host.list_vms.sort_by { |row| row["name"] }
    vms.map do |vm|
      vm["full_name"] = "#{vm["name"]}.#{host.name}"
      vm["readable_state"] = vm["state"].tr(" ", "_")

      vm["installation"] = installations.select { |x| x.vm_name == vm["name"] }.first
      vm["sidekiq"] = $vop.running_installation(host_name: host_name, vm_name: vm["name"]).first
      vm["install"] = $vop.installation_status(host_name: host_name, vm_name: vm["name"])

      ssh_status = false
      begin
        ssh_status = $vop.test_ssh(vm["full_name"])
      rescue => e
        $logger.warn("SSH test connect for #{vm["full_name"]} failed : #{e.message}")
      end

      vm["services"] = []
      vm["domains"] = []
      if ssh_status
        begin
          vm["services"] = $vop.detect_services(vm["full_name"])
        rescue => detail
          $logger.warn("error trying to detect services for #{vm["full_name"]} : #{detail.message}")
        end

        begin
          vm["domains"] = vms_with_domains.select { |x|
            x["proxy"] && x["proxy"]["hostname"] &&
            x["proxy"]["hostname"] == vm["name"]
          }
        rescue => e
          $logger.warn "could not list reverse proxies for #{host.name} : #{e.message}"
        end
      end

      vm
    end
  end

  def host_fragment
    host_data

    render partial: "host"
  end


end
