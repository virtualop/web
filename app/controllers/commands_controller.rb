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
    @plugin_name = @command.plugin.name

    if @command.nil?
      # TODO head :bad_request
      render text: "no such command : #{short_name}"
    else
      sources = @command.plugin.sources[:commands]
      @source = sources[params[:command]]

      @contributors = $vop.list_contributors(short_name)
    end
  end

  def entity
    $logger.info "displaying entity '#{params[:entity]}'"
    short_name = params[:entity].split(".").last

    @entity = $vop.entities[short_name]
    @plugin_name = @entity.plugin.name

    unless @entity.nil?
      sources = @entity.plugin.sources[:entities]
      @source = sources[params[:entity]]
    end
  end

end
