$game  = -> $('.game')
$input = -> $('input[type="text"]')

take_action = (url) ->
  $.ajax url,
    async: false
    success: (response) ->
      $game().html ""
      $input().val ""
      response = JSON.parse response
      if response.seen then $game().addClass("seen") else $game().removeClass("seen")
      $game().html response.markup
      if response.endgame then $input().hide() else $input().focus()
    timeout: 5

take_action 'start/'

$('form').submit (e) ->
  e.preventDefault()
  take_action 'execute/' + $input().val()
