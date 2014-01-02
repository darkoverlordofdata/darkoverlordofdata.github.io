#+--------------------------------------------------------------------+
#| run-muninn.coffee
#+--------------------------------------------------------------------+
#| Copyright DarkOverlordOfData (c) 2013
#+--------------------------------------------------------------------+
#|
#| This file is a part of Muninn
#|
#| Muninn is free software; you can copy, modify, and distribute
#| it under the terms of the MIT License
#|
#+--------------------------------------------------------------------+
#
# Instantiate Muninn
#
# Content Editor for Huginn
#
$ ->
  #
  # Load the plugin
  #
  require './muninn'
  muninn = $('.muninn').muninn()

