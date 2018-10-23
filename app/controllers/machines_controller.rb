class MachinesController < ApplicationController

  def index
    @machines = $vop.machines.sort_by(&:name)
  end

  def show
    @machine = $vop.machines[params[:machine]]
    @ssh_status = @machine.test_ssh

    @scan = @machine.scan_result

    # services
    begin
      services_data
    rescue => e
      logger.warn "could not fetch services : #{e.message}"
    end

    # traffic
    if @services && @services.include?("apache.apache")
      @domains = @machine.vhosts.select do |vhost|
        ! vhost["domain"].nil?
      end

      traffic_data
    else
      @domains = []
    end

    if params[:tab]
      logger.info "doing things specific to #{params[:tab]}"
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

      logger.debug "fetching log data for #{@machine.name}"

      interval = "hour"
      if @interval == 30
        interval = "minute"
      end

      # index the aggregated data by timestamp (and store them by result)
      @parsed = @machine.tail_and_parse_access_log(count: 500)
      aggregated = $vop.aggregate_logdata(data: @parsed, interval: interval)

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

      logger.debug "interval : #{@interval}"

      @last_bucket = nil
      if @interval == 360
        # we want the last 6 hours
        current_hour = Time.at(now.to_i - now.sec - (now.min * 60))
        logger.debug "current hour : #{current_hour}"
        5.downto(0) do |idx|
          hour = Time.at(current_hour.to_i - (60 * 60 * idx))
          next_hour = Time.at(current_hour.to_i - (60 * 60 * (idx-1)))
          @labels << hour.strftime("%H:00") + " - " + next_hour.strftime("%H:00")
          # TODO @last_bucket = hour.to_i if @last_bucket.nil?

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

          if histogram[:success][start_minute]
            @success << histogram[:success][start_minute]
          else
            @success << 0
          end

          if histogram[:failed][start_minute]
            @failed << histogram[:failed][start_minute]
          else
            @failed << 0
          end
        end
      end
    rescue => e
      logger.warn "could not get traffic for #{@machine.name} : #{e.message}"
      logger.debug e.backtrace.join("\n")
    end
  end

  def services_data
    @installables = []

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
