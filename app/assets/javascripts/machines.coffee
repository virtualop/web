# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

addParam = (param) ->
  console.log("adding param ", param)
  label_span = $('<span class="label" />').append(param.name + " : ")
  input_span = $('<span class="input_wrap"><input type="text" name="' + param.name + '" /></span>')
  param_div = $('<div class="param" />')
    .append(label_span)
    .append(input_span)
  $("#addServiceModal .params.container").append(param_div)

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
