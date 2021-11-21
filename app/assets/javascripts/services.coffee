# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

service_name = () ->
  $("#service_detail").data("name")

$ ->
  $("#service_detail a#add_package").click (event) ->    
    $("#service_detail .add_package textarea").show()

  $("#service_detail .add_package textarea").on "change", (event) ->
    serialized = $("#service_detail .add_package form").serialize()
    $.post "/services/parse/package", serialized, (parsed) ->
      payload = { packages: parsed, authenticity_token: $('[name="csrf-token"]')[0].content }
      $.post "/services/add/package/#{service_name()}", payload, (added) ->
        console.log "added", added

  $("#service_detail #install").click (event) ->
    payload = { authenticity_token: $('[name="csrf-token"]')[0].content }
    $.post "/services/install/#{service_name()}/#{$("#service_detail").data("machine")}", payload, (installed) ->
      console.log "installed", installed
