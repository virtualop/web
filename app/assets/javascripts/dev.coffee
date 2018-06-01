detailWindow = (event) ->
  $(event.target)
    .closest(".working-copy")
    .next(".working-copy-detail")

addChange = (change, target) ->
  status = $("<span />").html(change.raw)
  path = $("<span />").html(change.path)
  changeDiv = $("<div />").html(status.html() + path.html())
  $(target).append(changeDiv)

$ ->
  $("#dev-wrap .pull-button").on "ajax:success", (event) ->
    console.log("pulled.")

  $("#dev-wrap .changes-button").on "ajax:success", (event) ->
    [data, status, xhr] = event.detail
    detailWindow = $(event.target).closest(".working-copy").next(".working-copy-detail")
    $(detailWindow).show()

    contentArea = $(detailWindow).find(".content").first()
    contentArea.html("")
    addChange(change, contentArea) for change in data

  $("#dev-wrap").on "click", ".detail-close-button", (event) ->
    [data, status, xhr] = event.detail
    $(event.currentTarget).closest(".working-copy-detail").hide()

  $("#dev-wrap").on "click", ".switch-to-diff-button", (event) ->
    console.log("detail visible?", detailWindow.is(':visible'))

    [data, status, xhr] = event.detail

    header = detailWindow.find(".header .title").first()
    content = detailWindow.find(".content").first()
    content.html("")

    mode = detailWindow.data("mode")
    newMode = null
    if mode == "status"
      header.html("Diff")
      newMode = "diff"

      diff_url = "/dev/git_diff/" + detailWindow.data("name")
      $.get diff_url, (data) ->
        pre = $("<pre />").html(data)
        content.html(pre)
    else if mode == "diff"
      header.html("Changes")
      newMode = "status"

      status_url = "/dev/git_status/" + detailWindow.data("name")
      $.get status_url, (data) ->
        content.html("")
        addChange(change, content) for change in data

    detailWindow.data("mode", newMode)
