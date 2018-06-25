# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $(document).on "click", "#host_map i.fa-plus", ->
      host_element = $(this).closest(".host").first()
      new_vm_form = host_element.find(".vm_placeholder")
      new_vm_form.show()

  $(document).on "click", "#host_map .new_vm_form i.fa-times", (event) ->
    vm_element = event.currentTarget.closest(".vm")
    $(vm_element).hide()

  $(document).on "submit", ".new_vm_form", (event) ->
    event.preventDefault()
    new_vm_form = event.currentTarget
    console.log("submitting new_vm_form", new_vm_form)

    vm_name = $(this).find(".name_placeholder").first().val()
    host_name = $(this).closest(".host").data("machine")
    console.log("gonna create new vm " + vm_name + " on host " + host_name)

    payload =
      host_name: host_name,
      vm_name: vm_name,
      authenticity_token: $('[name="csrf-token"]')[0].content,

    memory = $("#newVmSettings #dropdownMenuButton").html()
    if memory
      payload["memory"] = memory
    console.log("payload", payload)

    $.post "/machines/new",
      payload,
      (data) ->
        console.log("VM " + vm_name + " installation has been started on " + host_name, $(this))
        installing_span = $('<span title="installing" class="vm_state_indicator installing">&nbsp;</span>&nbsp;<span>' + vm_name + '...</span>')
        vm_wrapper = $(new_vm_form).closest("div.vm_wrapper").first().html(installing_span)

        # startRefresh(host_element.data("machine"))
    false

  $("#newVmSettings .dropdown-menu.memory .dropdown-item").click (event) ->
    console.log("clicked memory", $(event.currentTarget).data("mb"))
    $("#dropdownMenuButton").html($(event.currentTarget).data("mb"))
