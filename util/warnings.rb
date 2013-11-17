def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE
  yield
ensure
  $VERBOSE = old_verbose
end
