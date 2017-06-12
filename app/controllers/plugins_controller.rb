class PluginsController < ApplicationController

  before_filter :plugin_from_params, only: [:show, :command]

  def plugin_from_params
    @plugin = $vop.plugins[params[:name]]
    raise "no such plugin" unless @plugin
  end

  def index
    @plugins = $vop.list_plugins.sort_by { |plugin| plugin[:name] }
  end

  def show
    @commands = $vop.list_commands(@plugin.name).sort_by do |command|
      command[:name]
    end

    @helpers = @plugin.sources.select do |key, value|
      key.to_s.start_with?("helpers") &&
      value.size > 0
    end
  end

  def command
    full_name = "#{@plugin.name}.#{params[:command]}"
    @command = @plugin.commands[full_name]

    unless @command
      raise "no such command"
    end

    @source = @plugin.sources[:commands][@command.name]
  end

  def helper
    full_name = "#{@plugin.name}.#{params[:helper]}"

  end

end
