detailWindow = (event) ->
  $(event.target)
    .closest(".working-copy")
    .next(".working-copy-detail")

addChange = (change, target) ->
  titleDiv = $("<div />").addClass("title")
    .append $("<span />").html(change.raw)
    .append $("<span />").html(change.path)
  detailDiv = $("<div />").addClass("detail")
  changeDiv = $("<div />").addClass("change")
    .data("path", change.path)
    .append titleDiv
    .append detailDiv
  $(target).append(changeDiv)

processChanges = (detail, data) ->
  detail.show()

  contentArea = detail.find(".content").first()
  contentArea.html("")

  addChange(change, contentArea) for change in data

  workingCopy = detail.prev(".working-copy")
  changesButton = workingCopy.find("changes-button").first()
  changesButton.html(data.length)


$ ->
  $("#dev-wrap .pull-button").on "ajax:success", (event) ->
    console.log("pulled.")

  $("#dev-wrap .changes-button").on "ajax:success", (event) ->
    [data, status, xhr] = event.detail
    detail = $(event.target).closest(".working-copy").next(".working-copy-detail")
    processChanges(detail, data)

  $("#dev-wrap").on "click", ".detail-close-button", (event) ->
    [data, status, xhr] = event.detail
    $(event.currentTarget).closest(".working-copy-detail").hide()

  $("#dev-wrap").on "click", ".refresh-button", (event) ->
    detail = $(event.currentTarget).closest(".working-copy-detail")
    workingCopy = $(detail).data("name")
    $.get "/dev/git_status/" + workingCopy + "?refresh=true", (data) ->
      processChanges(detail, data)

  $("#dev-wrap").on "click", ".change .title", (event) ->
    change = $(event.currentTarget).closest(".change")
    path = change.data("path")
    detail = $(event.currentTarget).closest(".working-copy-detail")
    workingCopy = $(detail).data("name")
    diff_url = "/dev/git_diff/" + workingCopy + "/" + path
    $.get diff_url, (data) ->
      pre = $("<pre />").html(data)
      detail = change.find(".detail").first()
      detail.append(pre)

  # $("#dev-wrap").on "click", ".switch-to-diff-button", (event) ->
  #   detailWindow = detailWindow(event)
  #   console.log("detail visible?", detailWindow.is(':visible'))
  #
  #   [data, status, xhr] = event.detail
  #
  #   header = detailWindow.find(".header .title").first()
  #   content = detailWindow.find(".content").first()
  #   content.html("")
  #
  #   mode = detailWindow.data("mode")
  #   newMode = null
  #   if mode == "status"
  #     header.html("Diff")
  #     newMode = "diff"
  #
  #     diff_url = "/dev/git_diff/" + detailWindow.data("name")
  #     $.get diff_url, (data) ->
  #       pre = $("<pre />").html(data)
  #       content.html(pre)
  #   else if mode == "diff"
  #     header.html("Changes")
  #     newMode = "status"
  #
  #     status_url = "/dev/git_status/" + detailWindow.data("name")
  #     $.get status_url, (data) ->
  #       content.html("")
  #       addChange(change, content) for change in data
  #
  #   detailWindow.data("mode", newMode)
