$.get 'start/', (response) ->
  $('.game').html response

$('form').submit (e) ->
  e.preventDefault()
  $input = $('input[type="text"]')
  $.ajax 'execute/' + $input.val(),
    async: false
    success: (response) ->
      $input.val("")
      $('.game').html response
      $input.focus()
    timeout: 5
