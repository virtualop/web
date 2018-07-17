$ ->
  $(".fa-cog.change-plugin-config").on "click", (event) ->
    console.log("changing plugin config", event.target)
    $(".config-param .value-write").toggle()
    $(".config-param .value-read").toggle()
    $(".config-wrap .buttons").toggle()

  $("i[new-plugin]").click (e) ->
    console.log("new plugin")
    $('#new_plugin_dialog').show()
