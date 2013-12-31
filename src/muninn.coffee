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
do ($ = jQuery, window, document) ->

  #
  # Muninn Plugin
  #
  # @param  [Object]  options hash
  # @return [Object]  the plugin
  #
  $::muninn = ($options = {}) ->

    $.data(@, 'muninn') ? $.data(@, 'muninn', new Muninn(@, $options))


  class Muninn

    saveAs = require('./FileSaver')
    yaml = require('yaml-js')
    path = require('path')

    default     :
      title     : ' '
      date      : 'select blog to edit'
      content   : ''
      css       : '//cdn.darkoverlordofdata.com/css/bootstrap.min.css'

    months: [
      'January', 'February', 'March', 'April', 'May', 'June'
      'July', 'August', 'September', 'October', 'November', 'December'
    ]

    options: null
    title: null
    date: null
    content: null
    file: null
    save: null
    filename: ''
    #
    # Create a new blog editor
    #
    # @param  [Object]  DOM Node
    # @param  [Object]  options hash
    # @return [Void]
    #
    constructor: ($container, $options) ->

      @options = $.extend(@default, $options)
      #
      # render the ui
      #

      $container.html """
          <input type="file" class="btn btn-primary muninn-file"/>
          <button class="btn btn-primary muninn-save">Save</button>
          <h1 class="editable muninn-title"></h1>
          <p  class="editable muted muninn-date"></p>
          <div class="editable muninn-content"></div>
        """
      @title = $container.find('.muninn-title')
      @date = $container.find('.muninn-date')
      @content = $container.find('.muninn-content')
      @file = $container.find('.muninn-file')
      @save = $container.find('.muninn-save')

      @title.html @options.title
      @date.html @options.date
      @content.html @options.content
      @save.hide()

      tinymce.init
        selector: 'h1.editable'
        inline: true
        menubar: false
        content_css: @options.css
        toolbar: 'undo redo'

      tinymce.init
        selector: 'p.editable'
        inline: true
        menubar: false
        content_css: @options.css
        toolbar: 'undo redo'

      tinymce.init
        selector: 'div.editable'
        inline: true
        menubar: false
        content_css: @options.css
        plugins: [
          "advlist autolink autosave link image lists charmap print preview hr anchor pagebreak spellchecker",
          "searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking",
          "table contextmenu directionality emoticons template textcolor paste fullpage textcolor"
        ]
        toolbar1: "newdocument fullpage | bold italic underline strikethrough | alignleft aligncenter alignright alignjustify | styleselect formatselect fontselect fontsizeselect",
        toolbar2: "cut copy paste | searchreplace | bullist numlist | outdent indent blockquote | undo redo | link unlink anchor image media code | inserttime preview | forecolor backcolor",
        toolbar3: "table | hr removeformat | subscript superscript | charmap emoticons | print fullscreen | ltr rtl | spellchecker | visualchars visualblocks nonbreaking template pagebreak restoredraft",

      @file.on 'change', ($e) =>

        files = $e.target.files
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
            @date.html $dd + ' ' + @months[$mm-1] +  ', ' + $yy

            @file.hide()
            @save.show()
            @filename = $file.name

        )(files[0])
        reader.readAsBinaryString files[0]

      @save.on 'click', ($e) =>

        $data = [
          "---\n"
          "title: #{@title.html()}\n"
          "---\n"
          @content.html()
        ]
        $blob = new Blob($data)
        saveAs($blob, "document.xhtml");