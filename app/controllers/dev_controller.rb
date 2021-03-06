include ERB::Util

class DevController < ApplicationController

  def reset
    render plain: sprintf("reset complete, %d plugins, %d commands", *$vop.reset)
  end

  def index
    @working_copies = $vop.working_copies_with_detail(machine: "localhost")
    @page_title = "dev"
    render :index
  end

  def refresh
    machine = $vop.machines["localhost"]
    machine.list_working_copies.each do |working_copy|
      machine.current_revision!("working_copy" => working_copy[:path])
      machine.git_status!("working_copy" => working_copy[:path])
    end

    index
  end

  def git_pull
    begin
      revision = $vop.git_pull(machine: "localhost", "working_copy" => working_copy_path())
      working_copy = {
        name: params[:working_copy],
        path: working_copy_path(),
        html_name: working_copy_path().gsub("/", "-"),
        current_revision: revision,
        changes: $vop.git_status(machine: "localhost", "working_copy" => working_copy_path())
      }
      render partial: "working_copy", locals: { working_copy: working_copy }, layout: nil
    rescue => e
      render partial: "error", status: 500, locals: { message: e.message, error: e }
    end
  end

  def git_push
    result = $vop.push_working_copy(machine: "localhost", "working_copy" => working_copy_path())
    render plain: result
  end

  def git_status
    p = {
      machine: "localhost",
      "working_copy" => working_copy_path()
    }

    result = if params[:refresh]
      $vop.git_status!(p)
    else
      $vop.git_status(p)
    end

    render json: result.to_json()
  end

  def git_diff
    result = $vop.git_diff(
      machine: "localhost",
      "working_copy" => working_copy_path(),
      "path_fragment" => params[:file] || ""
    )
    render plain: html_escape(result)
  end

  def new_diff
    @diff = $vop.git_diff(
      machine: "localhost",
      "working_copy" => working_copy_path(),
      "path_fragment" => params[:file] || ""
    )
  end

  def add_file
    $vop.add_file_to_version_control(
      machine: "localhost",
      "working_copy" => working_copy_path(),
      "file_name" => params[:file]
    )
  end

  def discard_change
    $vop.discard_change(
      machine: "localhost",
      "working_copy" => working_copy_path(),
      "file_name" => params[:file]
    )
  end

  def commit
    new_status = $vop.commit_changes(
      machine: "localhost",
      "working_copy" => working_copy_path,
      "comment" => params[:comment],
      "file" => params[:file]
    )
    render json: new_status.to_json()
  end

  private

  def working_copy_path
    "#{ENV["HOME"]}/projects/virtualop/#{params[:working_copy]}"
  end

end
