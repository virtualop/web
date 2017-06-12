class SandboxController < ApplicationController
  def index
    @identity = $vop.identity
    @plugins = $vop.list_plugins
  end

  def processes
    @processes = $vop.processes(machine: "localhost")
    $redis.set("processes", @processes.map{ |x| x[:command_short]})
  end

  def vms
    @vms = $vop.list_local_vms.map do |vm|
      case vm[:state]
      when 'shut off'
        vm[:action_name] = 'start_vm'
        vm[:icon_name] = 'fa-play'
      when 'running'
        vm[:action_name] = 'stop_vm'
        vm[:icon_name] = 'fa-stop'
      else
        raise "unknown run state '#{vm[:state]}' for VM '#{vm[:name]}'"
      end
      vm
    end
  end

  def start_vm
    raise "no VM name specified" unless params["name"]
    raise "no host specified" unless params["host"]

    $vop.start_vm("machine" => params["host"], "name" => params["name"])
    host_map(params["host"])
  end

  def stop_vm
    raise "no VM name specified" unless params["name"]
    raise "no host specified" unless params["host"]

    $vop.stop_vm("machine" => params["host"], "name" => params["name"])
    #render :text => "stopped"
    host_map(params["host"])
  end

  def vms_for_host(host_name)
    sorted_vms = $vop.list_vms("machine" => host_name).sort_by { |row| row["name"] }
    sorted_vms.each do |vm|
      vm["readable_state"] = vm["state"].tr(" ", "_")
    end
    sorted_vms
  end

  def moses
    @map = $vop.list_all_hosts.map do |row|
      sorted_vms = vms_for_host(row["name"])
      row["vms"] = sorted_vms
      row
    end
  end

  def host_map(host)
    host = host || params["host"]

    @host_row = $vop.list_all_hosts.select do |row|
      row["name"] == host
    end.first

    @host_row["vms"] = vms_for_host(host)

    render :layout => nil, :template => "sandbox/host_map"
  end

end
