disposable = (content) ->
  return $('<span class="disposable"/>').html(content)

$ ->
  $("#reset").on "click", (event) ->
    $(".reset .status").append(disposable("reset in progress..."))

    $.get "/dev/reset", (data) ->
      console.log("reset", data)
      $(".reset .status .disposable").remove()
      $(".reset .status").append(disposable(data))
      $('.reset .status .disposable').fadeOut(5000)
