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
  end
end
