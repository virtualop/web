detailWindow = (event) ->
  $(event.target)
    .closest(".working-copy")
    .next(".working-copy-detail")

addChange = (change, target) ->
  checkbox = $('<input type="checkbox" />').data("path", change.path)
  checkboxSpan = $("<span />").append(checkbox)
  titleDiv = $("<div />").addClass("title")
    .append checkboxSpan
    .append $("<span />").html(change.raw)
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

  addChange(change, contentArea) for change in data

  workingCopy = detail.prev(".working-copy")
  changesButton = workingCopy.find(".changes-button").first()
  console.log("updating changes button", changesButton)
  changesButton.html(data.length)


$ ->
  $("#dev-wrap .pull-button").on "ajax:success", (event) ->
    console.log("pulled.")

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
      files.append $('<input type="text" name="file" value="' + $(value).data("path") + '" />')


  $("#dev-wrap #commitModal").on "click", ".commit-button", (event) ->
    console.log("submitting", $("#commitModal form"))
    $("#commitModal form").submit()

    # detail = $(event.currentTarget).closest(".working-copy-detail")
    # console.log("detail", detail)
    # console.log("name", detail.data("name"))
    # payload =
    #   authenticity_token: $('meta[name="csrf-token"]').attr("content")
    #   working_copy: $(detail).data("name")
    #   comment: $("#commitModal textarea#comment").val()
    #   files: []
    #
    # $(detail).find(".change input[type=checkbox]:checked").each (idx, value) ->
    #   console.log("file", value)
    #   console.log("path", $(value).data("path"))
    #   payload.files.push($(value).data("path"))
    #
    # console.log("payload", payload)
    # $.post "/dev/commit", payload, (data) ->
    #   console.log("commit result", data)
