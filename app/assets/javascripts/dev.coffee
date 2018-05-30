addChange = (change, target) ->
  console.log("adding change", change)
  console.log("target", target)

  status = $("<span />").html(change.raw)
  path = $("<span />").html(change.path)
  changeDiv = $("<div />").html(status.html() + path.html())
  $(target).append(changeDiv)

$ ->
  $(".vop_log_button").click (event) ->
    console.log "starting to listen for vop_log"
    App.vopLogChannel = App.cable.subscriptions.create { channel: "VopLogChannel" },
      received: (data) ->
        console.log(data)

  $("#dev-wrap .pull-button").on "ajax:success", (event) ->
    console.log("pulled.")

  $("#dev-wrap .changes-button").on "ajax:success", (event) ->
    [data, status, xhr] = event.detail
    console.log("changes", data)
    console.log("event", event)

    detailWindow = "#working-copy-detail-" + event.currentTarget.dataset["workingCopy"]
    console.log("like this", detailWindow)
    detailWindowTemplate = "#detail-window-template"
    $(detailWindow).html($(detailWindowTemplate).html())
    $(detailWindow).show()
    addChange(change, detailWindow) for change in data

  $("#dev-wrap").on "click", ".detail-close-button", (event) ->
    [data, status, xhr] = event.detail
    console.log("closing", event.currentTarget)
    detail = $(event.currentTarget).closest(".working-copy-detail")
    console.log("detail", detail)
    detail.hide()
