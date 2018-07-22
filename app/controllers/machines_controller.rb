class MachinesController < ApplicationController

  def index
    @machines = $vop.machines.sort_by(&:name)
  end

  def show
    @machine = $vop.machines[params[:machine]]
    @ssh_status = @machine.test_ssh

    @scan = @machine.scan_result

    services_data

    if @services && @services.include?("apache.apache")
      @domains = @machine.vhosts.select do |vhost|
        ! vhost["domain"].nil?
      end

      traffic_data
    else
      @domains = []
    end
  end

  def traffic
    @machine = $vop.machines[params[:machine]]
    traffic_data

    render layout: nil
  end

  def traffic_data
    begin
      @interval = params[:interval] ? params[:interval].to_i : 30

      # index the aggregated data by timestamp
      success = []
      if @interval == 360
        success = @machine.aggregate_access_log_tail(count: 500)[:success]
      elsif @interval == 30
        logger.debug "fetching log data for #{@machine.name}"
        success = @machine.aggregate_access_log_tail(count: 500, interval: "minute")[:success]
      end

      by_timestamp = {}
      success.each do |entry|
        by_timestamp[entry.first] = entry.last
      end

      @traffic = []
      @labels = []
      now = Time.now

      logger.debug "interval : #{@interval}"

      if @interval == 360
        # we want the last 6 hours
        current_hour = Time.at(now.to_i - now.sec - (now.min * 60))
        logger.debug "current hour : #{current_hour}"
        5.downto(0) do |idx|
          hour = Time.at(current_hour.to_i - (60 * 60 * idx))
          next_hour = Time.at(current_hour.to_i - (60 * 60 * (idx-1)))
          @labels << hour.strftime("%H:00") + " - " + next_hour.strftime("%H:00")
          if by_timestamp[hour]
            @traffic << by_timestamp[hour]
          else
            @traffic << 0
          end
        end
      elsif @interval == 30
        # or the last 30 minutes
        current_minute = Time.at(now.to_i - now.sec)
        logger.debug "current minute : #{current_minute}"
        30.downto(0) do |idx|
          start_minute = Time.at(current_minute.to_i - (60 * idx))
          @labels << start_minute.strftime("%H:%M")
          if by_timestamp[start_minute]
            @traffic << by_timestamp[start_minute]
          else
            @traffic << 0
          end
        end
      end
    rescue => e
      logger.warn "could not get traffic for #{@machine.name} : #{e.message}"
      logger.debug e.backtrace.join("\n")
    end
  end

  def services_data
    @machine = $vop.machines[params[:machine]]
    @services = @machine.detect_services.sort
    @installables = $vop.services
      .sort_by { |x| x.name }
      #.delete_if { |x| @services && @services.include?(x.name) }
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
    request = ::Vop::Request.new $vop, "new_machine", p
    $vop.execute_async(request)
  end

  def delete
  end

  def service_icon
    service = $vop.services.select { |x| x.name == params[:service] }.first
    icon_path = File.join(service.plugin.plugin_dir("files"), service.data[:icon])

    if icon_path
      send_data open(icon_path, "rb") { |f| f.read }
    else
      send_data open("#{Rails.root}/public/blank.png", "rb") { |f| f.read }
    end
  end

  def service_params
    service = $vop.services.select { |x| x.name == params[:service] }.first

    render json: service.data["params"].to_json()
  end

  def install_service
    service = $vop.services.select { |x| x.name == params[:service] }.first
    puts "installing service #{params[:service]} on #{params[:machine]}"

    # pass on all params except these
    blacklist = %w|authenticity_token controller action|
    p = {}
    params.each do |k,v|
      unless blacklist.include? k
        p[k] = v
      end
    end

    $vop.install_service_async(p)
  end

  def scan
    $vop.inspect_async(params[:machine]).to_json
    render json: {status: "scan has been scheduled"}.to_json
  end

end
