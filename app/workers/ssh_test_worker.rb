require "sidekiq"

class SshTestWorker
  include Sidekiq::Worker

  def perform(machine_name, no_cache = false)
    machine = $vop.machines[machine_name]
    if no_cache
      $vop.invalidate_cache("command" => "test_ssh", "raw_params" => { "machine" => machine.name })
    end
    machine.test_ssh
  end
end
