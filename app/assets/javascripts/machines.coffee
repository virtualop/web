# dynamically loaded parameters for the "add service" modal
addParam = (param) ->
  label_span = $('<span class="label" />').append(param.name + " : ")
  input_span = $('<span class="input_wrap"><input type="text" name="' + param.name + '" /></span>')
  param_div = $('<div class="param" />')
    .append(label_span)
    .append(input_span)
  $("#addServiceModal .params.container").append(param_div)

# traffic log data that is received from ActionCable
addTailLine = (line) ->
  date = new Date(line.timestamp_unix * 1000)
  timestamp = date
    .toLocaleString('de-DE', month: "2-digit", year: "numeric", day: "numeric", hour: "numeric", minute: "numeric", second: "numeric")
    .replace /,/, ""
  new_tr = $('<tr>')
    .append( $('<td>').append(timestamp) )
    .append( $('<td>').append(line.remote_ip) )
    .append( $('<td>').append(line.status) )
    .append( $('<td>').append(line.request) )
  $("#trafficLog tbody").prepend(new_tr)

addTail = (input) ->
  console.log("adding tail", input)
  if input != null && input["content"] != null
    addTailLine(line) for line in input["content"] when line != null

addTailLineToLog = (line) ->
  date = new Date(line.timestamp * 1000)
  timestamp = date
    .toLocaleString('de-DE', month: "2-digit", year: "numeric", day: "2-digit", hour: "numeric", minute: "numeric", second: "numeric")
    .replace /,/, ""
  new_tr = $('<tr>')
    .append( $('<td>').append(timestamp) )
    .append( $('<td>').append(line.http_host) )
    .append( $('<td>').append(line.source_ip) )
    .append( $('<td>').append(line.return_code) )
    .append( $('<td>').append(line.request_path) )
    .append( $('<td>').append(line.user_agent) )
  $("#trafficLog tbody").prepend(new_tr)

addTailToLog = (input) ->
  if input != null && input["content"] != null
    addTailLineToLog(line) for line in input["content"] when line != null

# update traffic graph (different ActionCable)
addBucket = (line, value, timestamp) ->
  line.shift()
  line.push(value)
  d = new Date(0)
  d.setUTCSeconds(timestamp)
  myChart.data.labels.shift()
  myChart.data.labels.push(d.toLocaleString('de-DE', hour: '2-digit', minute: '2-digit'))

addGraph = (graph) ->
  if graph.content.success && graph.content.success.length > 0
    graph.content.success.forEach (success) ->
      timestamp = success[0]
      value = success[1]
      lastBucket = $("#trafficGraph").data("last-bucket")
      line = myChart.data.datasets[0].data
      if lastBucket == timestamp
        idx = line.length - 1
        line[idx] = line[idx] + value
      else
        if timestamp > lastBucket
          distance = timestamp - lastBucket
          if (distance > 60)
            count = (distance / 60) - 1
            addBucket(line, 0, timestamp - idx * 60) for idx in [count..1]

          $("#trafficGraph").data("last-bucket", timestamp)
          addBucket(line, value, timestamp)
        else
          console.log("received data from the past", timestamp)
          console.log("lastBucket", lastBucket)

      myChart.update()

$ ->
  # scan
  $(".scan-button").click (event) ->
    console.log("scan button clicked", event)
    machine = event.currentTarget.dataset["machine"]
    console.log("machine", machine)
    $.get "/machines/scan/" + machine, (data) ->
      console.log("scan initiated")

  # addServiceModal
  $("#addServiceModal").on "show.bs.modal", (event) ->
    $("#addServiceModal #dropdownMenuButton").text("select service")
    $("#addServiceModal .params.container").html("")

  $("#addServiceModal .dropdown-menu .dropdown-item").click (event) ->
    serviceName = event.currentTarget.text
    console.log("service dropdown item clicked", serviceName)

    $("#addServiceModal #dropdownMenuButton").text(serviceName)
    $("#addServiceModal form input.service").val(serviceName)

    $("#addServiceModal .params.container").html("")
    $.get "/machines/service_params/" + serviceName, (data) ->
      addParam(param) for param in data

  # add service
  $(".add-service-button").click (event) ->
    modal = $("#addServiceModal")
    machineName = modal.data("machine")
    serialized = $(modal).find("form").serialize()
    service_name = modal.find("form input.service").val()
    console.log("service", service_name)
    $.post "/machines/install_service", serialized, (data) ->
      console.log("service installation initialized.", data)
      App.installationStatusChannel = App.cable.subscriptions.create { channel: "InstallationStatus", machine: machineName },
        received: (json_data) ->
          console.log("received installation status update", json_data)
          update = JSON.parse(json_data)
          console.log("update", update)
          if (update.service == service_name)
            App.installationStatusChannel.unsubscribe()
            console.log("unsubscribed")
          $.get "/machines/services/" + machineName, (svc_data) ->
            $("#services").replaceWith(svc_data)


    $("#addServiceModal").modal("hide")

  # graph interval dropdown
  $(document).on "click", "#intervalDropdown .dropdown-item", (event) ->
    interval = $(event.target).data("interval")
    console.log("interval", interval)
    machine = $(event.target).closest(".machine")
    machineName = $(machine).data("machine")
    console.log("machine", machineName)
    $.get "/machines/traffic/#{machineName}?interval=#{interval}", (data) ->
      console.log("new traffic data", data)
      $("#trafficGraph").replaceWith(data)

  $(document).on "wheel", "#trafficGraph canvas", (event) ->
    original = event.originalEvent
    console.log("deltaY", original.deltaY)
    event.preventDefault()

  # scan notifications
  last_scan = $("#last_scan")
  if last_scan.length > 0
    App.scanChannel = App.cable.subscriptions.create { channel: "ScanChannel", machine: $("#machine").data("machine") },
      received: (json_data) ->
        scan = JSON.parse(json_data)
        console.log "scan result", scan.content
        location.reload()

  # log tail
  trafficLog = $("#trafficLog")
  if trafficLog.length > 0
    logFile = $(trafficLog).data("path")
    if logFile
      App.tailChannel = App.cable.subscriptions.create { channel: "TailChannel", machine: $("#machine").data("machine"), log: logFile, style: "new" },
        received: (json_data) ->
          tail = JSON.parse(json_data)
          addTailToLog(tail)

      App.graphChannel = App.cable.subscriptions.create { channel: "GraphChannel", machine: $("#machine").data("machine"), log: logFile, style: "new" },
        received: (json_data) ->
          graph = JSON.parse(json_data)
          addGraph(graph)
    else
      App.tailChannel = App.cable.subscriptions.create { channel: "TailChannel", machine: $("#machine").data("machine"), log: "/var/log/apache2/access.log" },
        received: (json_data) ->
          tail = JSON.parse(json_data)
          addTail(tail)

      App.graphChannel = App.cable.subscriptions.create { channel: "GraphChannel", machine: $("#machine").data("machine"), log: "/var/log/apache2/access.log" },
        received: (json_data) ->
          graph = JSON.parse(json_data)
          if graph.content.success && graph.content.success.length > 0
              graph.content.success.forEach (success) ->
                timestamp = success[0]
                value = success[1]
                lastBucket = $("#trafficGraph").data("last-bucket")
                line = myChart.data.datasets[0].data
                if lastBucket == timestamp
                  idx = line.length - 1
                  line[idx] = line[idx] + value
                else
                  if timestamp > lastBucket
                    distance = timestamp - lastBucket
                    if (distance > 60)
                      count = (distance / 60) - 1
                      addBucket(line, 0, timestamp - idx * 60) for idx in [count..1]

                    $("#trafficGraph").data("last-bucket", timestamp)
                    addBucket(line, value, timestamp)
                  else
                    console.log("received data from the past", timestamp)

                myChart.update()

  screenshots = $("#screenshot")
  if screenshots.length > 0
    screenshot = screenshots[0]
    setInterval () ->
      machineName = $(screenshot).closest(".machine").data("machine")
      console.log("machine name", machineName)
      console.log("screenshot", screenshot)

      url = "/machines/screenshot/#{machineName}?ts=#{new Date().getTime()}"
      image = new Image()
      image.src = url
      console.log("image", image)

      screenshot.src = url
    , 20000

  doughnuts = $("#memoryDoughnut")
  if doughnuts.length > 0
    doughnut = doughnuts[0]
    console.log("doughnut found", doughnut)
    App.scanChannel = App.cable.subscriptions.create { channel: "MemoryUpdateChannel", machine: $("#machine").data("machine") },
      received: (json_data) ->
        update = JSON.parse(json_data)
        console.log "memory update", update.content
        newData = []
        update.content.forEach (row) ->
          console.log "row", row
          if row.area == "Mem"
            newData.push(row.used)
            newData.push(row.available)
          if row.area == "Swap"
            newData.push(row.used)
        doughnutChart.data.datasets[0].data = newData
        doughnutChart.update()
