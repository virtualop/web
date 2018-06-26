detailWindow = (event) ->
  $(event.target)
    .closest(".working-copy")
    .next(".working-copy-detail")

addChange = (change, target) ->
  checkbox = $('<input type="checkbox" />').data("path", change.path)
  checkboxSpan = $("<span />").append(checkbox)
  addDiv = $("<div />")
  addDiv.html("add")
  addDiv.addClass("add-file")
  addDiv.data("path", change.path)
  detail = $(target).closest(".working-copy-detail")
  addDiv.data("working_copy", detail.data("name"))
  addDiv.data("detail", detail)
  statusSpan = $("<span />")
    .addClass("status")
    .html(change.raw)
    .data("container", "#dev-wrap")
    .popover(content: addDiv, html: true)
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
  $("#dev-wrap").on "ajax:success", ".pull-button", (event) ->
    [data, status, xhr] = event.detail
    working_copy = $(event.currentTarget).closest(".working-copy")[0]
    $(working_copy).replaceWith(data.body.innerHTML)

  $("#dev-wrap .changes-button").on "ajax:success", (event) ->
    [data, status, xhr] = event.detail
    detail = $(event.target).closest(".working-copy").next(".working-copy-detail")
    processChanges(detail, data)

  $("#dev-wrap").on "click", ".refresh-button", (event) ->
    detail = $(event.currentTarget).closest(".working-copy-detail")
    workingCopy = $(detail).data("name")
    $.get "/dev/git_status/" + workingCopy + "?refresh=true", (data) ->
      processChanges(detail, data)

  $("#dev-wrap").on "click", ".checkbox-button", (event) ->
    detail = $(event.target).closest(".working-copy-detail")
    detail.find(".change input[type=checkbox]").toggle()
    detail.find(".selection-buttons").toggle()
    detail.find(".select-all").toggle()

  $("#dev-wrap").on "click", ".select-all", (event) ->
    $(".change .title input[type=checkbox]").prop("checked", $(event.target).prop("checked"))

  $("#dev-wrap").on "click", ".detail-close-button", (event) ->
    [data, status, xhr] = event.detail
    $(event.currentTarget).closest(".working-copy-detail").hide()

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
        # TODO [untested] copied from refresh button:
        $.get "/dev/git_status/" + workingCopy + "?refresh=true", (newData) ->
          processChanges(detail, newData)

  $("#commitModal").on "show.bs.modal", (event) ->
    console.log("showing commit modal")

  $("#dev-wrap").on "click", ".working-copy-detail .selection-buttons .commit-button", (event) ->
    detail = $(event.currentTarget).closest(".working-copy-detail")
    console.log("showing commit form, working copy", detail.data("name"))
    $("#commitModal form input[name=working_copy]").val(detail.data("name"))

    files = $("#commitModal form div.files")
    files.html("")
    $(detail).find(".change input[type=checkbox]:checked").each (idx, value) ->
      console.log("path", $(value).data("path"))
      files.append $('<input type="text" name="file[]" value="' + $(value).data("path") + '" />')

  $("#dev-wrap #commitModal").on "click", ".commit-button", (event) ->
    console.log("submitting", $("#commitModal form"))
    $("#commitModal").data("workingCopyDetail", $(event.currentTarget).closest(".working-copy-detail"))
    $("#commitModal form").submit()
    $("#commitModal").modal("hide")

  $("#dev-wrap").on "ajax:success", "#commitModal form", (event) ->
    console.log("form submitted successfully", event)
    #workingCopy = $("#commitModal form input[name=working_copy]").val()
    #console.log("workingCopy", workingCopy)
    detail = $("#commitModal").data("workingCopyDetail")
    console.log("detail", detail)
    workingCopy = $(detail).data("name")
    console.log("workingCopy", workingCopy)
    $.get "/dev/git_status/" + workingCopy + "?refresh=true", (data) ->
      console.log("got changes", data)
      processChanges(detail, data)

  $('[data-toggle="popover"]').popover()
