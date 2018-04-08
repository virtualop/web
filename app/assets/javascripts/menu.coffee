$ ->
  $("i[data-toggle]").click (e) ->
    e.preventDefault()
    target = "#" + $(this).data("toggle")
    $(target).toggle()

  $("#toolbar i.fa-bathtub").click (e) ->
    $.get '/dev/reset', (data) ->
      $('body').append data
