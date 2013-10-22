async_timeout = 5

update_display = (new_text) ->
  $('.game').html new_text

$.ajax 'start/',
  async: false
  success: (response) ->
    update_display response
  timeout: async_timeout

$('form').submit (e) ->
  e.preventDefault()
  $input = $('input[type="text"]')
  $.ajax 'execute/' + $input.val(),
    async: false
    success: (response) ->
      $input.val("")
      update_display response
      $input.focus()
    timeout: async_timeout
