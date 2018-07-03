$ ->
  $(document).on "click", ".error.veryglobal", (event) ->
    $(event.target).closest(".error").fadeOut()
