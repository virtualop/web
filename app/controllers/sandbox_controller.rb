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

    $vop.start_vm("machine" => "localhost", "name" => params["name"])
    render :text => "started"
  end

  def stop_vm
    raise "no VM name specified" unless params["name"]

    $vop.stop_vm("machine" => "localhost", "name" => params["name"])
    render :text => "stopped"
  end

end
