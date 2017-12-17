class CommandsController < ApplicationController

  def index
    $logger.info "listing commands"
    @commands = $vop.commands.values.sort_by do |x|
      x.short_name
    end
  end

  def command
    $logger.info "displaying command '#{params[:command]}'"
    short_name = params[:command].split(".").last
    @command = $vop.commands[short_name]

    if @command.nil?
      #head :bad_request
      render text: "no such command : #{short_name}"
    else
      sources = @command.plugin.sources[:commands]
      @source = sources[params[:command]]
    end
  end

end
