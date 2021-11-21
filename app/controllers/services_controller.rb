class ServicesController < ApplicationController

  def index
    @services = $vop.known_services.sort_by(&:name)
  end

  def show
    service
    packages
    if params[:machine]
      machine
      package_status
    end
  end

  def parse_package
    package_names = $vop.parse_package_input(params[:input])
    render plain: package_names.join(" ")
  end

  def add_package
    source_file = plugin.sources[:services][service_name][:file_name]
    Rails.logger.info "about to write into #{source_file}"

    # TODO : might want to filter existing ones
    packages_to_add = params[:packages]
    package_line = "deploy package: %w|#{packages_to_add}|"

    localhost = $vop.machines["localhost"]
    localhost.append_to_file(file_name: source_file, content: package_line)

    # TODO invalidate service cache

    render plain: params[:packages]
  end

  def package_status
    installed = @machine.list_packages.map { |p| p["name"] }
    available = @machine.available_packages
    @package_status = packages.map do |package|
      {
        name: package,
        installed: installed.include?(package),
        available: available.include?(package)
      }
    end
  end

  def install
    machine.install_service(service_name)

    render plain: "ok"
  end

  private

  def service_name
    params[:service]
  end

  def service
    @service = $vop.known_services[service_name]
  end

  def machine
    @machine = $vop.machines[params[:machine]]
  end

  def packages
    @packages = @service.data.dig("install", "package")&.sort || []
  end

  def plugin
    plugin_name = service.data["plugin_name"]
    $vop.plugin(plugin_name)
  end

end
