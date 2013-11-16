$game  = -> $('.game')
$input = -> $('input[type="text"]')

take_action = (url) ->
  $.ajax url,
    async: false
    success: (response) ->
      update_game = (response) ->
        $game().html ""
        if response.seen then $game().addClass("seen") else $game().removeClass("seen")
        $game().html response.markup
        if response.endgame then $input().hide() else $input().focus()

      $input().val ""
      response = JSON.parse response
      if response.wait
        old_placeholder = $input().prop('placeholder')
        $game().addClass("wait")
        $input().prop('disabled', true)
        $input().prop('placeholder', "Waiting...")
        window.setTimeout ->
          $game().removeClass("wait")
          $input().prop('disabled', false)
          $input().prop('placeholder', old_placeholder)
          update_game response
        , response.wait * 1000
      else
        update_game response
    timeout: 5

take_action 'start/'

$('form').submit (e) ->
  e.preventDefault()
  take_action 'execute/' + $input().val()
