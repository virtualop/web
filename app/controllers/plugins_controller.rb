class PluginsController < ApplicationController

  def index
    all_plugins = $vop.plugins
    @core = all_plugins.select { |x| x.options[:core] }
    @plugins = all_plugins - @core

    [ @core, @plugins ].each do |list|
      list.sort_by! { |plugin| plugin.name }
    end
  end

  def show
    $logger.info "showing #{params[:plugin]}"
    @plugin = $vop.plugin(params[:plugin])
  end

  def create
    $logger.info "creating plugin #{params[:name]}"
    $vop.new_plugin("name" => params[:name])

    index
    render "index"
  end

end
