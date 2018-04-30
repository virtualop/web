class DevController < ApplicationController

  def index
    @working_copies = [
      "#{ENV['HOME']}/projects"
    ]
    #flash.now[:notice] = "beeblebrox!"
  end

  def reset
    render plain: sprintf("reset complete, %d plugins, %d commands", *$vop.reset)
  end

end
