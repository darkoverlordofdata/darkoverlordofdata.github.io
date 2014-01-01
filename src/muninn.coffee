#+--------------------------------------------------------------------+
#| muninn.coffee
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
# Muninn
#
# Content Editor for Huginn
#
# Dependencies:
#
#   jquery 2.0.2
#   jquery-ui 1.10.3
#   tinymce 4.0
#   yaml-js 0.0.8
#
do ($ = jQuery, window, document) ->

  #
  # Muninn Plugin
  #
  # @param  [Boolean] create true = new, false = edit
  # @param  [Object]  options hash
  # @return [Object]  the plugin
  #
  $::muninn = ($create = false, $options = {}) ->

#    $('head').append """
#      <style>
#      </style>
#      """
    $.data(@, 'muninn') ? $.data(@, 'muninn', new Muninn(@, $create, $options))


  class Muninn

    path = require('path')
    yaml = require('yaml-js')
    saveAs = require('./FileSaver')
    chosen = require('chosen-jquery-browserify')

    default     :
      title     : 'Title'
      date      : 'd MM, yy'
      tags      : '#tag-cloud'

    options: null
    title: null
    date: null
    content: null
    file: null
    save: null
    filename: ''
    select: null
    chosen: null
    tags: null
    #
    # Create a new blog editor
    #
    # @param  [Object]  DOM Node
    # @param  [Object]  options hash
    # @return [Void]
    #
    constructor: ($container, $create, $options) ->

      @options = $.extend(@default, $options)
      @tags = []
      for $tag in $(@options.tags).text().split(/\s+/).sort()
        if $tag isnt ''
          @tags.push $tag

      #
      # render the ui
      #

      $container.html """
          <h1 class="muninn-title"></h1>
          <input class="muninn-date muted" type="text" placeholder="Enter Date" />
          <div class="muninn-content"></div>
          <div class="muninn-select"></div>
          <hr />
          <a class="muninn-load btn btn-primary">Load Post...</a>
          <a class="muninn-save btn">Save Post...</a>
          <input class="muninn-file hidden" type="file" />

        """
      @title = $container.find('.muninn-title')
      @date = $container.find('.muninn-date')
      @content = $container.find('.muninn-content')
      @load = $container.find('.muninn-load')
      @file = $container.find('.muninn-file')
      @save = $container.find('.muninn-save')
      @date.datepicker dateFormat: @options.date
      @select = $container.find('.muninn-select')

      @setTags []

      if $create
        @load.hide()
        @title.html 'New Post'
        @content.html """
            <p>Create a new blog post, and save to your _drafts folder.</p>
            <p>To view your changes, use either:</p>
            <code>$ huginn build</code>
            <p>or</p>
            <code>$ jekyll build</code>
          """
      else
        @title.html @options.title
        @content.html """
            <p>Select a post to edit from your _posts or _drafts folder.</p>
            <p>To view your changes, use either:</p>
            <code>$ huginn build</code>
            <p>or</p>
            <code>$ jekyll build</code>
          """

      tinymce.init
        selector: '.muninn-title'
        inline: true
        menubar: false
        toolbar: 'undo redo'

      tinymce.init
        selector: '.muninn-content'
        inline: true
        menubar: false
        plugins: [
          'advlist autolink autosave link image lists charmap print preview hr anchor pagebreak spellchecker',
          'searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking',
          'table contextmenu directionality emoticons template textcolor paste fullpage textcolor'
        ]
        toolbar1: 'newdocument fullpage | bold italic underline strikethrough | alignleft aligncenter alignright alignjustify | styleselect formatselect fontselect fontsizeselect',
        toolbar2: 'cut copy paste | searchreplace | bullist numlist | outdent indent blockquote | undo redo | link unlink anchor image media code | inserttime preview | forecolor backcolor',
        toolbar3: 'table | hr removeformat | subscript superscript | charmap emoticons | print fullscreen | ltr rtl | spellchecker | visualchars visualblocks nonbreaking template pagebreak restoredraft',

      @setTags []

      #
      # Input[type=file] Change Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @file.on 'change', ($e) =>

        $file = $e.target.files[0]
        if not /\.html$/.test($file.name) and not /\.md$/.test($file.name)
          return alert 'Invalid Filetype'

        reader = new FileReader
        reader.onload = ( ($file) =>
          return ($e) =>
            $buf = $e.target.result
            $hdr = {}
            if $buf[0..3] is '---\n'
              # pull out the header and parse with yaml
              $buf = $buf.split('---\n')
              $hdr = yaml.load($buf[1])
              $buf = $buf[2]

            $ext = path.extname($file.name)
            $name = path.basename($file.name, $ext)
            $seg = $name.split('-')
            $yy = $seg.shift()
            $mm = $seg.shift()
            $dd = $seg.shift()

            @content.html $buf
            @title.html $hdr.title
            @date.datepicker('setDate', new Date($yy, $mm-1, $dd))
            @filename = $file.name
            $tags = $hdr?.tags.split(' ') ? []
            @setTags $tags


        )($file)
        reader.readAsBinaryString $file

      #
      # Load Post Click Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @load.on 'click', ($e) =>
        @file.get(0).click()

      #
      # Save Post Click Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @save.on 'click', ($e) =>

        $tags = []
        $data = [
          "---\n"
          "title: #{@title.html()}\n"
          "tags: #{$tags.join(' ')}"
          "---\n"
          @content.html()
        ]
        saveAs new Blob($data), @filename

    #
    # Set Tags
    #
    # @param  [Array<String>]  list of selected tags
    # @return [Void]
    #
    setTags: ($tags) ->

      $html = "<select data-placeholder=\"select tag\" multiple class=\"chosen-select\">"
      for $tag in @tags
        if $tags.indexOf($tag) is -1
          $html += "<option>#{$tag}</option>"
        else
          $html += "<option selected>#{$tag}</option>"

      $html += "</select>"

      @select.html $html
      @chosen = @select.find('.chosen-select')
      @chosen.css width: '350px'


      #
      # Change Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @chosen.chosen().change ($e) ->

        #
        # update the tags list
        #
        @tags = []
        for $option in $e.target
          if $option.selected
            @tags.push $option.label

