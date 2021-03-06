detailWindow = (event) ->
  $(event.target)
    .closest(".working-copy")
    .next(".working-copy-detail")

addChange = (change, target) ->
  checkbox = $('<input type="checkbox" />').data("path", change.path)
  checkboxSpan = $("<span />").append(checkbox)

  detail = $(target).closest(".working-copy-detail")

  addDiv = $("<div />")
  addDiv.html("add")
  addDiv.addClass("add-file")
  addDiv.data("path", change.path)
  addDiv.data("working_copy", detail.data("name"))
  addDiv.data("detail", detail)

  discardDiv = $("<div />")
  discardDiv.html("discard")
  discardDiv.addClass("discard-change")
  discardDiv.data("path", change.path)
  discardDiv.data("working_copy", detail.data("name"))
  discardDiv.data("detail", detail)

  popover = $("<div />")
  popover.append(addDiv)
  popover.append(discardDiv)

  statusSpan = $("<span />")
    .addClass("status")
    .html(change.raw)
    .data("container", "#dev-wrap")
    .popover(content: popover, html: true)

  titleDiv = $("<div />").addClass("title")
    .append checkboxSpan
    .append statusSpan
    .append $("<span />").addClass("path").html(change.path)

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

  # extra checkbox for "select all"
  checkbox = $('<input type="checkbox" />')
  checkboxSpan = $("<span />")
    .addClass "select-all"
    .append(checkbox)
  contentArea.append(checkboxSpan)

  addChange(change, contentArea) for change in data

  workingCopy = detail.prev(".working-copy")
  changesButton = workingCopy.find(".changes-button").first()
  changesButton.html(data.length)

  detail.find(".selection-buttons").hide()


$ ->
  # pull
  $("#dev-wrap").on "ajax:success", ".pull-button", (event) ->
    console.log("pull result", event.detail)
    [data, status, xhr] = event.detail
    working_copy = $(event.currentTarget).closest(".working-copy")[0]
    console.log("got pull result", data.body.innerHTML)
    $(working_copy).replaceWith(data.body.innerHTML)
    name = $(working_copy).data("name")
    $(".working-copy#" + name).effect("highlight")

  $("#dev-wrap").on "ajax:error", ".pull-button", (event) ->
    [data, status, xhr] = event.detail
    detail = $(event.target).closest(".working-copy").next(".working-copy-detail")
    $(detail).append(data.body.innerHTML)

  # push
  $("#dev-wrap").on "ajax:success", ".push-button", (event) ->
    [data, status, xhr] = event.detail
    working_copy = $(event.currentTarget).closest(".working-copy")[0]
    console.log("got push result", data)
    name = $(working_copy).data("name")
    $(".working-copy#" + name).effect("highlight")

  # changes
  $("#dev-wrap").on "ajax:success", ".changes-button", (event) ->
    [data, status, xhr] = event.detail
    detail = $(event.target).closest(".working-copy").next(".working-copy-detail")
    processChanges(detail, data)

  # refresh
  $("#dev-wrap").on "click", ".refresh-button", (event) ->
    detail = $(event.currentTarget).closest(".working-copy-detail")
    workingCopy = $(detail).prev(".working-copy").first()
    console.log("workingCopy", workingCopy)
    changesButton = $(workingCopy).find(".changes-button").first()
    changesButton[0].innerHTML = "&hellip;"
    workingCopyName = $(detail).data("name")
    $.get "/dev/git_status/" + workingCopyName + "?refresh=true", (data) ->
      processChanges(detail, data)

  # checkbox
  $("#dev-wrap").on "click", ".checkbox-button", (event) ->
    detail = $(event.target).closest(".working-copy-detail")
    detail.find(".change input[type=checkbox]").toggle()
    detail.find(".selection-buttons").toggle()
    detail.find(".select-all").toggle()

  # select all
  $("#dev-wrap").on "click", ".select-all", (event) ->
    $(".change .title input[type=checkbox]").prop("checked", $(event.target).prop("checked"))

  # close
  $("#dev-wrap").on "click", ".detail-close-button", (event) ->
    # [data, status, xhr] = event.detail
    $(event.currentTarget).closest(".working-copy-detail").hide()

  # diff
  $("#dev-wrap").on "click", ".change .title .path", (event) ->
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

  # add file
  $("#dev-wrap").on "click", ".add-file", (event) ->
    addFile = event.currentTarget
    workingCopy = $(addFile).data("working_copy")
    detail = $(addFile).data("detail")
    console.log("add file", event.currentTarget)
    console.log("path", $(addFile).data("path"))
    console.log("workingCopy", workingCopy)
    $.post "/dev/add_file/" + workingCopy + "/" + $(addFile).data("path"),
      authenticity_token: $('[name="csrf-token"]')[0].content,
      (data) ->
        console.log("added file.")
        $("#dev-wrap .popover").popover("hide")
        $.get "/dev/git_status/" + workingCopy + "?refresh=true", (newData) ->
          processChanges(detail, newData)

  # discard change
  $("#dev-wrap").on "click", ".discard-change", (event) ->
    console.log("about to discard change")
    discardChange = event.currentTarget
    workingCopy = $(discardChange).data("working_copy")
    detail = $(discardChange).data("detail")
    console.log("discarding changed file", discardChange)
    console.log("path", $(discardChange).data("path"))
    console.log("workingCopy", workingCopy)
    $.post "/dev/discard_change/" + workingCopy + "/" + $(discardChange).data("path"),
      authenticity_token: $('[name="csrf-token"]')[0].content,
      (data) ->
        console.log("discarded change to file " + $(discardChange).data("path"))
        $("#dev-wrap .popover").popover("hide")
        $.get "/dev/git_status/" + workingCopy + "?refresh=true", (newData) ->
          processChanges(detail, newData)

  # commit form
  $("#dev-wrap").on "click", ".working-copy-detail .selection-buttons .commit-button", (event) ->
    detail = $(event.currentTarget).closest(".working-copy-detail")
    console.log("showing commit form, working copy", detail.data("name"))
    $("#commitModal textarea[name=comment]").val("")
    $("#commitModal form input[name=working_copy]").val(detail.data("name"))
    $("#commitModal form").data("detail", detail)

    labels = $("#commitModal form div.file_labels")
    labels.html("")
    files = $("#commitModal form div.files")
    files.html("")
    $(detail).find(".change input[type=checkbox]:checked").each (idx, value) ->
      console.log("path", $(value).data("path"))
      files.append $('<input type="hidden" name="file[]" value="' + $(value).data("path") + '" />')
      labels.append $('<div>' + $(value).data("path") + '</div>')

  # commit
  $("#dev-wrap #commitModal").on "click", ".commit-button", (event) ->
    detail = $("#commitModal form").data("detail")
    workingCopy = $(detail).data("name")
    $.post "/dev/commit",
      $("#commitModal form").serialize(),
      (data) ->
        console.log("commit result", data)
        processChanges(detail, data)
        $("#commitModal").modal("hide")
        $(detail).effect("highlight")
        workingCopyDiv = $("#" + workingCopy)
        pullButton = $(workingCopyDiv).find("button.pull-button")
        pullButton.click()

  $('[data-toggle="popover"]').popover()
