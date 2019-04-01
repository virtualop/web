module MachinesHelper

  def render_box(name)
    part = controller.render_to_string partial: name
    render partial: "machine_box", locals: { name: name, part: part }
  end

end
