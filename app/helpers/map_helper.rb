require "benchmark"

module MapHelper

  # helper that loads VMs and machine objects for a list of host names
  # returns an array holding
  # [0] an array of machine entities for the hosts
  # [1] a hash holding VMs per host name
  def vms_for_host_names(host_names)
    host_vms = {}
    hosts = []

    host_names.each do |host_name|
      host_vms[host_name] = vm_list(host_name)
      hosts << $vop.machines[host_name]
    end

    [ hosts, host_vms ]
  end

  def vm_list(host_name = params[:machine])
    host = $vop.machines[host_name]
    logger.info "host map : #{host.name}"

    vms = host.list_vms.sort_by { |row| row["name"] }
    vms.map do |vm|
      vm["full_name"] = "#{vm["name"]}.#{host.name}"
      vm["readable_state"] = vm["state"].tr(" ", "_")
      vm["installation_status"] = $vop.installation_status(host_name: host.name, vm_name: vm["name"])

      full_name = "#{vm["name"]}.#{host.name}"
      machine = $vop.machines[full_name]
      scan = machine.scan_result

      vm["services"] = scan["services"]
      vm["domains"] = scan["domains"]

      vm
    end
  end

end
