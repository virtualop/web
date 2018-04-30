$ ->
  $("#toolbar #reset").on "ajax:success", (event) ->
    $('body').append event.detail[0]

  $("i[data-toggle]").click (e) ->
    e.preventDefault()
    target = "#" + $(this).data("toggle")
    $(target).toggle()

  # $("#toolbar i.fa-sync").click (e) ->
  #   $.get '/dev/reset', (data) ->
  #     $('body').append data
