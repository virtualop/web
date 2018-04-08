# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
    $("#machines i.fa-trash").click (e) ->
      target = $(this).data("machine")
      url = "machines/" + target + "/delete_record"
      $.get url, (data) ->
        machine_element = "#machines #" + target.replace(/\./g, "_")
        $(machine_element).remove();

updateHost = () ->
    console.log("updating host")

$ ->
    $("#hostmap i.fa-plus").click (e) ->
      host_element = $(this).closest(".host").first()
      host_name = host_element.data("machine")
      new_vm_form = $('<form class="new_vm_form"><input type="text" class="name_placeholder" placeholder="name" /></form>')
      new_vm_form.submit ->
        vm_name = $(this).find('.name_placeholder').first().val()
        console.log("submitting new vm form", vm_name)
        console.log("gonna create new VM on machine", host_name)

        $.post "/machines/" + host_name + "/new_vm",
          vm_name: vm_name
          (data) ->
            console.log("VM " + vm_name + " installation has been started on " + host_name, $(this))
            installing_span = $('<span title="installing" class="vm_state_indicator installing">&nbsp;</span>&nbsp;<span>' + vm_name + '...</span>')
            vm_wrapper = $(new_vm_form).closest("div.vm_wrapper").first().html(installing_span)
            setTimeout(updateHost, 2000)
        false

      pseudo_vm = $('<li class="vm">').append($('<div class="vm_wrapper">').append(new_vm_form))
      $(host_element).find("ul").first().append(pseudo_vm)

$ ->
  $("#hostmap .vm .toolbar i.fa-trash").click (e) ->
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

$ ->
  $("#hostmap .vm").hover(
    ->
      $(this).find('.toolbar').show()
    ->
      $(this).find('.toolbar').hide()
  )
