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
  $(target).append changeDiv

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
    detail = change.find(".detail").first()

    detailLoaded = detail.find("pre").length > 0
    if detailLoaded
      detail.html("")
    else
      workingCopy = change.closest(".working-copy-detail")
      diff_url = "/dev/git_diff/" + $(workingCopy).data("name") + "/" + change.data("path")
      $.get diff_url, (data) ->
        pre = $("<pre />").html(data)
        diffWrap = $("<div />").addClass("diff-wrap").append(pre)
        detail.append(diffWrap)
