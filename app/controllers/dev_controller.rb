class DevController < ApplicationController

  def index
    @working_copies = [
      "#{ENV['HOME']}/projects"
    ]
    #flash.now[:notice] = "beeblebrox!"
  end

  def reset
    $vop.reset
    render text: "foo"
  end

end
