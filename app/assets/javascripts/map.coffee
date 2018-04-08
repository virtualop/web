# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

hostElementFromName = (host_name) ->
  host_id = host_name.replace /\./, '_'
  return $("#" + host_id).first()

startRefresh = (host_name) ->
  setTimeout ->
    updateHost(host_name)
  , 3000
  console.log("scheduled fetch for ", host_name)
  host_element = hostElementFromName(host_name)
  host_element.find(".toolbar .fa-refresh").first().hide()
  host_element.find(".toolbar .fa-hand-paper-o").first().show()

stopRefresh = (host_name) ->
  host_id = host_name.replace /\./, '_'
  host_element = $("#" + host_id).first()
  host_element.data("no_refresh", true)
  host_element.find(".toolbar .fa-refresh").first().show()
  host_element.find(".toolbar .fa-hand-paper-o").first().hide()

updateHost = (host_name) ->
  console.log("fetching for host ", host_name)
  $.get "/map/host_fragment/" + host_name,
    (data) ->
      host_id = host_name.replace /\./, '_'
      host_element = $("#" + host_id).first()
      no_refresh = host_element.data("no_refresh")
      console.log("received host fragment", host_element)
      host_element.replaceWith(data)
      if not no_refresh
        console.log("scheduling next fetch")
        startRefresh(host_name)

$(document).on "click", "#host_map i.fa-plus", ->
    host_element = $(this).closest(".host").first()
    host_name = host_element.data("machine")
    new_vm_form = $('<form class="new_vm_form"><input type="text" class="name_placeholder" placeholder="name" /></form>')
    new_vm_form.submit ->
      vm_name = $(this).find('.name_placeholder').first().val()
      console.log("gonna create new VM " + vm_name + "on machine", host_name)

      $.post "/map/" + host_name + "/new_vm",
        vm_name: vm_name
        (data) ->
          console.log("VM " + vm_name + " installation has been started on " + host_name, $(this))
          installing_span = $('<span title="installing" class="vm_state_indicator installing">&nbsp;</span>&nbsp;<span>' + vm_name + '...</span>')
          vm_wrapper = $(new_vm_form).closest("div.vm_wrapper").first().html(installing_span)

          startRefresh(host_element.data("machine"))
      false

    pseudo_vm = $('<li class="vm">').append($('<div class="vm_wrapper">').append(new_vm_form))
    $(host_element).find("ul").first().append(pseudo_vm)

$(document).on "mouseenter", "#host_map .vm", ->
    $(this).find('.toolbar').show()

$(document).on "mouseleave", "#host_map .vm", ->
    $(this).find('.toolbar').hide()

$(document).on "click", "#host_map .toolbar i.fa-refresh", ->
  host_element = $(this).closest(".host").first()
  startRefresh(host_element.data("machine"))

$(document).on "click", "#host_map .toolbar .fa-hand-paper-o", ->
  host_element = $(this).closest(".host").first()
  stopRefresh(host_element.data("machine"))

$(document).on "click", "#host_map .vm .toolbar i.fa-trash", ->
  host_element = $(this).closest(".host").first()
  host_name = host_element.data("machine")
  vm_element = $(this).closest(".vm").first()
  vm_name = vm_element.data("name")
  console.log("deleting vm " + vm_name + " on " + host_name)

  $.post "/machines/" + host_name + "/delete_vm",
    name: vm_name
    (data) ->
      console.log("VM " + vm_name + " has been deleted.")
      vm_element.hide()
