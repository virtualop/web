$ ->
  $("i[data-toggle]").click (e) ->
    e.preventDefault()
    target = "#" + $(this).data("toggle")
    $(target).toggle()
