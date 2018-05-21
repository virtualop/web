# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $(".scan_button").click (event) ->
    console.log("scan button clicked", event)
    machine = event.currentTarget.dataset["machine"]
    console.log("machine", machine)
    $.get "/machines/scan/" + machine, (data) ->
      console.log("scan initiated")
