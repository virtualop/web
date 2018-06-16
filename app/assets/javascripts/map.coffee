# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $(document).on "click", "#host_map i.fa-plus", ->
      host_element = $(this).closest(".host").first()
      host_name = host_element.data("machine")
      new_vm_form = $('<form class="new_vm_form"><input type="text" class="name_placeholder" placeholder="name" /><i class="fa fa-times"></i></form>')
      new_vm_form.submit ->
        vm_name = $(this).find('.name_placeholder').first().val()
        console.log("gonna create new VM " + vm_name + " on machine", host_name)

        $.post "/machines/new",
          host_name: host_name,
          vm_name: vm_name,
          authenticity_token: $('[name="csrf-token"]')[0].content,
          (data) ->
            console.log("VM " + vm_name + " installation has been started on " + host_name, $(this))
            installing_span = $('<span title="installing" class="vm_state_indicator installing">&nbsp;</span>&nbsp;<span>' + vm_name + '...</span>')
            vm_wrapper = $(new_vm_form).closest("div.vm_wrapper").first().html(installing_span)

            # startRefresh(host_element.data("machine"))
        false

      pseudo_vm = $('<li class="vm">').append($('<div class="vm_wrapper">').append(new_vm_form))
      $(host_element).find("ul").first().prepend(pseudo_vm)

  $(document).on "click", "#host_map .new_vm_form i.fa-times", (event) ->
    vm_element = event.currentTarget.closest(".vm")
    vm_element.remove()
