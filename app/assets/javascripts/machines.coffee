# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

addParam = (param) ->
  label_span = $('<span class="label" />').append(param.name + " : ")
  input_span = $('<span class="input_wrap"><input type="text" name="' + param.name + '" /></span>')
  param_div = $('<div class="param" />')
    .append(label_span)
    .append(input_span)
  $("#addServiceModal .params.container").append(param_div)

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
  if input != null && input["content"] != null
    addTailLine(line) for line in input["content"] when line != null

addBucket = (line, value, timestamp) ->
  line.shift()
  line.push(value)
  d = new Date(0)
  d.setUTCSeconds(timestamp)
  myChart.data.labels.shift()
  myChart.data.labels.push(d.toLocaleString('de-DE', hour: '2-digit', minute: '2-digit'))

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
    console.log("showing service modal", event)
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

  # graph interval
  $(document).on "click", "#intervalDropdown .dropdown-item", (event) ->
    interval = $(event.target).data("interval")
    console.log("interval", interval)
    machine = $(event.target).closest(".machine")
    machineName = $(machine).data("machine")
    console.log("machine", machineName)
    $.get "/machines/traffic/#{machineName}?interval=#{interval}", (data) ->
      console.log("new traffic data", data)
      $("#trafficGraph").replaceWith(data)

  # log tail
  trafficLog = $("#trafficLog")
  if trafficLog.length > 0
    App.tailChannel = App.cable.subscriptions.create { channel: "TailChannel", machine: $("#machine").data("machine"), log: "/var/log/apache2/access.log" },
      received: (json_data) ->
        tail = JSON.parse(json_data)
        addTail(tail)

    App.graphChannel = App.cable.subscriptions.create { channel: "GraphChannel", machine: $("#machine").data("machine"), log: "/var/log/apache2/access.log" },
      received: (json_data) ->
        graph = JSON.parse(json_data)
        if graph.content.success && graph.content.success.length > 0
            graph.content.success.forEach (success) ->
              console.log("one success", success)
              timestamp = success[0]
              value = success[1]
              console.log("pushing onto dataset for timestamp " + timestamp + " : " + value, myChart.data.datasets[0].data)
              lastBucket = $("#trafficGraph").data("last-bucket")
              console.log("last bucket", lastBucket)

              line = myChart.data.datasets[0].data
              console.log("checking lastBucket " + lastBucket + " vs. timestamp " + timestamp, line)
              if lastBucket == timestamp
                idx = line.length - 1
                line[idx] = line[idx] + value
                console.log("adding to last bucket, current value", line[idx])
              else
                if timestamp > lastBucket
                  distance = timestamp - lastBucket
                  console.log("distance", distance)

                  if (distance > 60)
                    count = (distance / 60) - 1
                    console.log("need to fill up " + count + " buckets", line)
                    addBucket(line, 0, timestamp - idx * 60) for idx in [count..1]
                    console.log("line now", line)

                  console.log("setting lastBucket", timestamp)
                  $("#trafficGraph").data("last-bucket", timestamp)
                  addBucket(line, value, timestamp)
                else
                  console.log("received data from the past", timestamp)

              myChart.update()
