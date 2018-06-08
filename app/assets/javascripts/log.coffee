# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

addCommandDiv = (data) ->
  command = $("<span />").html(data["command"])

  params = $("<span />")
  key_count = Object.keys(data["params"]).length
  if key_count > 0
    params.html(JSON.stringify(data["params"]))

  newDiv = $("<div/>").append(command)
  newDiv.append(params)
  newDiv.addClass("command")
  newDiv.attr("id", data["id"])
  newDiv.css("margin-left", data["level"] * 2 + "px")
  $("#log").append(newDiv)
  h = $("#log").height()
  $(".content-body").first().scrollTop(h)

App.listen_for_vop_log = ->
  console.log "starting to listen for vop_log"
  App.vopLogChannel = App.cable.subscriptions.create { channel: "VopLogChannel" },
    received: (json_data) ->
      data = JSON.parse(json_data)
      console.log(data)

      if data["state"] == "before"
        addCommandDiv(data)
      else
        command = $("##{data["id"]}")
        span = $(command).find('span').first()
        span.html("[#{data["status"]}] " + span.html())
