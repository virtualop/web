# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@attach = () ->
  $("a.vm_action").on "ajax:complete", (xhr, status) ->
    if status.status == 200
      host_name = $(xhr.target).data("host")
      $("#" + host_name + ".host").replaceWith(status.responseText)
      attach()
    else
      console.log("TODO: houston")

$(document).ready ->
    attach()
