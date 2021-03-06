module MachinesHelper

  def render_box(name, size = 4)
    part = controller.render_to_string partial: name
    render partial: "machine_box", locals: { name: name, part: part, size: size }
  end

end
