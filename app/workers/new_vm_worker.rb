require "sidekiq"

class NewVmWorker
  include Sidekiq::Worker

  def perform(host_name, vm_name)
    machine = $vop.machines[host_name]
    begin
      machine.new_machine("name" => vm_name)
    rescue => e
      logger.error "problem in new_machine : #{e.message}"
      logger.error e.backtrace
    end

    # logger.info "starting to install VM '#{vm_name}' on '#{host_name}'"
    #
    # # TODO  maybe archive old installation records?
    # installation = Installation.find_or_create_by(host_name: host_name, vm_name: vm_name)
    # installation.status = :started
    # installation.save!
    # begin
    #   machine.new_machine("name" => vm_name)
    #   #machine.new_vm_from_latest_ubuntu("name" => vm_name)
    #   installation.status = :finished
    # rescue => e
    #   installation.status = :failed
    #   logger.error("installation of vm #{vm_name} on host #{host_name} failed: #{e.message}\n#{e.backtrace.join("\n")}")
    # ensure
    #   installation.save!
    # end
    #
    # logger.info "installation finished : #{installation.status}"
    #
    # machine.list_vms!
    # machine.processes!
    # machine.vnc_ports!

    # $vop.invalidate_cache("command" => "list_vms", "raw_params" => {"machine" => host_name})
    # $vop.invalidate_cache("command" => "processes", "raw_params" => {"machine" => host_name})
    # $vop.invalidate_cache("command" => "vnc_ports", "raw_params" => {"machine" => host_name})
  end
end
