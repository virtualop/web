# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

addCommandDiv = (data) ->
  command = $("<span />").html(data["command"])

  params = $("<span />")
  key_count = Object.keys(data["params"]).length
  if key_count > 0
    params.html(JSON.stringify(data["params"]))

  newDiv = $("<div/>")
    .append(command)
    .append(params)
  newDiv.addClass("command")
  newDiv.attr("id", data["id"])
  newDiv.data("origin", data["origin"])
  newDiv.css("margin-left", data["level"] * 2 + "px")
  $("#log").append(newDiv)

  console.log "added newDiv", newDiv

  h = $("#log").height()
  $(".content-body").first().scrollTop(h)

updateCommandDiv = (data) ->
  console.log "updating div", data["id"]
  command = $("##{data["id"]}")
  span = $(command).find('span').first()
  span.html("[#{data["status"]}] " + span.html())

handleOrigin = (data) ->
  for_id = data.origin.replace(/:/g, "_").replace(/@/g, "_").replace(/!/g, "_")
  console.log "replaced", for_id

  existing = $("#origin div#" + for_id)
  if (existing.length > 0)
    console.log("origin div exists already, update", existing.first())
  else
    console.log "adding new originDiv", for_id
    titleSpan = $("<span />").html(data.origin)
    originDiv = $("<div/>")
      .append(titleSpan)
      .attr("id", for_id)
      .addClass("origin")
      .addClass("enabled")
    $("#origin").append(originDiv)

maybeToggle = (div, origin) ->
  div_origin = $(div).data("origin")
  if (div_origin == origin)
    console.log("toggling div with origin", div_origin)
    $(div).toggle()

toggleOrigin = (span) ->
  origin = $(span).html()
  originDiv = $(span).closest(".origin")
  originDiv.toggleClass("enabled")
  maybeToggle(d, origin) for d in $("#log div")

App.listen_for_vop_log = ->
  console.log "starting to listen for vop_log"
  App.vopLogChannel = App.cable.subscriptions.create { channel: "VopLogChannel" },
    received: (json_data) ->
      data = JSON.parse(json_data)
      console.log(data)

      handleOrigin(data)

      if data["phase"] == "before"
        addCommandDiv(data)
      else
        updateCommandDiv(data)

$ ->
  $("#origin").on "click", "span", (event) ->
    toggleOrigin(event.target)
