class DevController < ApplicationController

  def reset
    render plain: sprintf("reset complete, %d plugins, %d commands", *$vop.reset)
  end

  def index

    vop_root = "#{ENV["HOME"]}/projects/virtualop"

    @working_copy_names = %w|vop plugins services web|
    @working_copies = @working_copy_names.map do |x|
      hash = { name: x,
        path: "#{vop_root}/#{x}",
      }
      hash[:html_name] = hash[:path].gsub("/", "-")
      hash
    end

    @changes = {}
    @working_copies.each do |working_copy|
      name = working_copy[:name]
      @changes[name] = $vop.git_status(machine: "localhost", "working_copy" => working_copy[:path])
    end

    #flash.now[:notice] = "beeblebrox!"
  end

  def git_pull
    result = $vop.git_pull(machine: "localhost", "working_copy" => working_copy_path())
    last_line = result.lines.last
    render json: last_line.to_json()
  end

  def git_status
    result = $vop.git_status(machine: "localhost", "working_copy" => working_copy_path())
    render json: result.to_json()
  end

  def git_diff
    result = $vop.git_diff(machine: "localhost", "working_copy" => working_copy_path())
    render plain: result
  end

  private

  def working_copy_path
    "#{ENV["HOME"]}/projects/virtualop/#{params[:working_copy]}"
  end

end
