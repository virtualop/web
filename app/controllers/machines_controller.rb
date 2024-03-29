class MachinesController < ApplicationController

  def index
    @machines = $vop.scan_results.map do |name, scan_result|
      scan_result["name"] = name
      scan_result["last_seen"] = Time.at(scan_result["scan_from"]) unless scan_result["scan_from"].nil?
      scan_result
    end

    respond_to do |format|
      format.html
      format.json { render :json => @machines }
    end
  end

  def show
    @machine = $vop.machines[params[:machine]]
    @page_title = @machine.name
    @scan = @machine.scan_result
    @ssh_status = @scan["ssh_status"]

    # tabs
    if params[:tab]
      logger.info "doing things specific to #{params[:tab]}"

      case params[:tab]
      when "files"
        @path = params[:path] || "~"
        @files = @machine.list_files(@path)
      end

      render template: "machines/tabs/#{params[:tab]}"
    else
      default_machine_data
    end
  end

  def default_machine_data
    # installation status
    if @machine.metadata["type"] == "vm"
      @installation_status = $vop.installation_status(host_name: @machine.parent.name, vm_name: @machine.short_name)
      logger.info "installation status : #{@installation_status.pretty_inspect}"
    end

    # no need to try to load services and traffic while provisioning
    if @installation_status.nil? || @installation_status != "provisioning"
      # memory doughnut
      @memory = {}
      @machine.memory(unit: "m").each do |line|
        @memory[line["area"]] = line
      end

      # services
      begin
        services_data
      rescue => e
        logger.warn "could not fetch services : #{e.message}"
      end

      # traffic
      if @services && @services.include?("apache.apache")
        @domains = @machine.domains

        traffic_data
      else
        @domains = []
      end
    end
  end

  def traffic
    @machine = $vop.machines[params[:machine]]
    traffic_data

    render layout: nil, partial: "graph"
  end

  def traffic_data
    @has_traffic_log = nil
    begin
      @log_path = "/var/log/apache2/access.vop.log"
      new_style = @machine.file_exists(@log_path)
      if new_style
        @parsed = @machine.tail_and_parse(log: @log_path, count: 500).map do |line|
          next if line.nil?
          line[:formatted_timestamp] = Time.at(line[:timestamp].to_i).strftime("%d.%m.%Y %H:%M:%S")
          line
        end.compact
      else
        # read the last lines of the access log
        @parsed = @machine.tail_and_parse_access_log(count: 500).map do |line|
          line[:formatted_timestamp] = Time.at(line[:timestamp_unix]).strftime("%d.%m.%Y %H:%M:%S")
          line
        end
      end

      # index the aggregated data by timestamp (and store by result)
      @interval = params[:interval] ? params[:interval].to_i : 30
      logger.debug "interval : #{@interval}"
      interval = @interval == 30 ? "minute" : "hour"
      aggregated = if new_style
        $vop.aggregate(data: @parsed, interval: interval)
      else
        $vop.aggregate_logdata(data: @parsed, interval: interval)
      end

      histogram = {
        success: {},
        failed: {}
      }

      success = aggregated[:success] || []
      success.each do |entry|
        histogram[:success][entry.first] = entry.last
      end

      failed = aggregated[:failure] || []
      failed.each do |entry|
        histogram[:failed][entry.first] = entry.last
      end

      @success = []
      @failed = []
      @labels = []
      now = Time.now

      @last_bucket = nil
      if @interval == 360
        # we want the last 6 hours
        current_hour = Time.at(now.to_i - now.sec - (now.min * 60))
        logger.debug "current hour : #{current_hour}"
        5.downto(0) do |idx|
          hour = Time.at(current_hour.to_i - (60 * 60 * idx))
          @labels << hour.strftime("%H:00")
          @last_bucket = hour.to_i if @last_bucket.nil?

          if histogram[:success][hour]
            @success << histogram[:success][hour]
          else
            @success << 0
          end

          if histogram[:failed][hour]
            @failed << histogram[:failed][hour]
          else
            @failed << 0
          end
        end
      elsif @interval == 30
        # or the last 30 minutes
        current_minute = Time.at(now.to_i - now.sec)
        logger.debug "current minute : #{current_minute}"
        30.downto(0) do |idx|
          start_minute = Time.at(current_minute.to_i - (60 * idx))
          @labels << start_minute.strftime("%H:%M")
          @last_bucket = start_minute.to_i
          key = new_style ? @last_bucket : start_minute

          if histogram[:success][key]
            @success << histogram[:success][key]
          else
            @success << 0
          end

          if histogram[:failed][key]
            @failed << histogram[:failed][key]
          else
            @failed << 0
          end
        end
      end

      @has_traffic_log = true
    rescue => e
      flash.alert = "could not get traffic for #{@machine.name} : #{e.message}"
      logger.warn "could not get traffic for #{@machine.name} : #{e.message}"
      logger.debug e.backtrace.join("\n")
      @has_traffic_log = false
    end
  end

  def services_data
    @installables = []

    @machine = $vop.machines[params[:machine]]
    @services = @machine.detect_services.sort
    @installables = $vop.known_services.sort_by { |x| x.name } #.delete_if { |x| @services && @services.include?(x.name) }
  end

  def services
    services_data

    render partial: "services"
  end

  def new
    $logger.info "new machine #{params[:vm_name]} on #{params[:host_name]}"

    p = {
      "machine" => params[:host_name],
      "name" => params[:vm_name]
    }
    if params[:memory]
      p[:memory] = params[:memory]
    end
    if params[:disk]
      p[:disk_size] = params[:disk]
    end
    request = ::Vop::Request.new $vop, "new_machine", p
    $vop.execute_async(request)
  end

  def delete
    $logger.info "deleting machine #{params[:machine]}"

  end

  def service_icon
    service = $vop.known_services.select { |x| x.name == params[:service] }.first
    raise "no service found with name #{params[:service]} - known services:\n#{$vop.known_services.map(&:name)}" if service.nil?
    icon_path = service.data["icon"]

    if icon_path
      send_data open(icon_path, "rb") { |f| f.read }
    else
      send_data open("#{Rails.root}/public/blank.png", "rb") { |f| f.read }
    end
  end

  def service_params
    service = $vop.known_services.select { |x| x.name == params[:service] }.first

    render json: service.data["params"].to_json()
  end

  def install_service
    service = $vop.known_services.select { |x| x.name == params[:service] }.first
    logger.info "installing service #{params[:service]} on #{params[:machine]}"

    # pass on all params except these
    blacklist = %w|authenticity_token controller action|
    p = {}
    params.each do |k,v|
      unless blacklist.include? k
        p[k] = v unless v.nil? || v == ""
      end
    end

    $vop.install_service_async(p)
  end

  def scan
    $vop.inspect_async(params[:machine])
    render json: { status: "scan has been scheduled" }.to_json
  end

  def screenshot
    machine_name = params[:machine]
    if machine_name.end_with? ".ppm"
      machine_name = machine_name[0..-5]
    end

    machine = $vop.machines[machine_name]
    path = machine.screenshot_vm
    localhost = $vop.machines["localhost"]
    screenshots_dir = "/tmp/vop_screenshots"
    local_file = "#{screenshots_dir}/#{machine_name}.ppm"
    png_file = local_file.split(".")[0..-2].join(".") + ".png"

    logger.debug "downloading screenshot from #{path}"

    localhost.mkdirs screenshots_dir
    machine.parent.scp_down(remote_path: path, local_path: local_file)

    localhost.ssh("convert #{local_file} #{png_file}")

    send_data open(png_file, "rb") { |f| f.read }
  end

end
