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
# External dependencies:
#
#   jquery 2.0.2
#   jquery-ui 1.10.3
#   tinymce 4.0
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

    path = require('path')                        # browserifyjs 3.16.1
    yaml = require('yaml-js')                     # yaml-js 0.0.8
    saveAs = require('./FileSaver')               # filesaver.js 2013.1.23
    chosen = require('chosen-jquery-browserify')  # chosen 1.0.0
    beautify = require('js-beautify').html        # js-beautify 1.4.2

    default         : # Options:
      title         : 'Title'
      date          : 'd MM, yy'
      tags          : '#tag-cloud'

    options: null   # constructor options hash
    selected: null  # list of chosen tags
    tags: null      # list of tags
    filename: ''    # filename
    status: 'none'  # comment status
    hdr: null       # template header info
                    #
                    # UI Elements
    title: null     # blog title
    date: null      # blog date
    content: null   # blog content
    chosen: null    # dropdown list of available tags
    file: null      # hidden input[type='file']
    save: null      # save file button
    load: null      # load file button
    select: null    # tag selector
    tag: null       # new tag input
    add: null       # add tag button
    comments: null  # radio buttons comment status

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
      # Grab the tag list from the tag-cloud on this page
      #
      @tags = []
      for $tag in $(@options.tags).text().split(/\s+/).sort()
        if $tag isnt ''
          @tags.push $tag

      #
      # render the ui
      #
      $container.html """
        <div class="span12">
          <h1 class="muninn-title"></h1>
          <input class="muninn-date muted" type="text" placeholder="Enter Date" />
          <div class="muninn-content"></div>
          <br />
        </div>
        <div class="well span7">
          <div class="muninn-select"></div>
          <div class="input-append">
            <input placeholder="Ener new tag" class="muninn-tag span6" type="text">
            <button class="muninn-add btn" type="button"><i class="icon icon-tag"> </i></button>
          </div>
          <label class="radio">
            <input class="muninn-comments" name="muninn-comments" id="muninn-comments-none" type="radio" value="none" checked> Comments are not enabled
          </label>
          <label class="radio">
            <input class="muninn-comments" name="muninn-comments" id="muninn-comments-open" type="radio" value="open"> Comments are Open
          </label>
          <label class="radio">
            <input class="muninn-comments" name="muninn-comments" id="muninn-comments-closed" type="radio" value="closed"> Comments are Closed
          </label>
          <div class="span6"></div>
          <div class="btn-group">
          <a class="muninn-load btn btn-primary"><i class="icon icon-upload icon-white"> </i> Load...</a>
          <a class="muninn-save btn"><i class="icon icon-download"> </i> Save...</a>
          </div>
          <input class="muninn-file hidden" type="file" />
        </div>
        """

      #
      # cache the ui elements
      #
      @title = $container.find('.muninn-title')
      @date = $container.find('.muninn-date')
      @content = $container.find('.muninn-content')
      @select = $container.find('.muninn-select')
      @tag = $container.find('.muninn-tag')
      @add = $container.find('.muninn-add')
      @comments = $container.find('.muninn-comments')
      @file = $container.find('.muninn-file')
      @load = $container.find('.muninn-load')
      @save = $container.find('.muninn-save')


      #
      # Title edit
      #
      @title.html @options.title
      tinymce.init
        selector: '.muninn-title'
        inline: true
        menubar: false
        toolbar: 'undo redo'


      #
      # Date edit
      #
      @date.datepicker dateFormat: @options.date

      #
      # Content edit
      #
      @content.html """
          <div class="muted">
          <p>Use this page to edit or create new posts. Create a new post,
          or select a post to edit from your _posts or _drafts folder.</p>
          <p>To update your site with your changes, use either:</p>
          <code>$ huginn build</code>
          <p>or</p>
          <code>$ jekyll build</code>
          </div>
        """
      tinymce.init
        selector: '.muninn-content'
        inline: true
        menubar: false
        remove_linebreaks : false
        force_p_newlines : false
        force_br_newlines : false
        plugins: [
          'advlist autolink autosave link image lists charmap print preview hr anchor pagebreak spellchecker',
          'searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking',
          'table contextmenu directionality emoticons template textcolor paste fullpage textcolor'
        ]
        toolbar1: 'newdocument fullpage | bold italic underline strikethrough | alignleft aligncenter alignright alignjustify | styleselect formatselect fontselect fontsizeselect',
        toolbar2: 'cut copy paste | searchreplace | bullist numlist | outdent indent blockquote | undo redo | link unlink anchor image media code | inserttime preview | forecolor backcolor',
        toolbar3: 'table | hr removeformat | subscript superscript | charmap emoticons | print fullscreen | ltr rtl | spellchecker | visualchars visualblocks nonbreaking template pagebreak restoredraft',

      #
      # Tags edit
      #
      @selected = []
      @setTags @selected

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
            @hdr = {}
            if $buf[0..3] is '---\n'
              # pull out the header and parse with yaml
              $buf = $buf.split('---\n')
              @hdr = yaml.load($buf[1])
              $buf = $buf[2]

            $ext = path.extname($file.name)
            $name = path.basename($file.name, $ext)
            $seg = $name.split('-')
            $yy = $seg.shift()
            $mm = $seg.shift()
            $dd = $seg.shift()

            @content.html $buf
            @title.html @hdr.title
            @date.datepicker('setDate', new Date($yy, $mm-1, $dd))
            @filename = $file.name
            @selected = @hdr?.tags.split(' ') ? []
            @comments = @hdr?.comments ? 'none'
            $container.find('#muninn-comments-'+@comments).prop 'checked', true

            @setTags @selected


        )($file)
        reader.readAsBinaryString $file

      #
      # Load Button Click Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @load.on 'click', ($e) =>
        @file.get(0).click()

      #
      # Save Button Click Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @save.on 'click', ($e) =>

        @hdr = {} unless @hdr?
        @hdr.title = @title.text()
        @hdr.tags = @selected.join(' ')
        @hdr.comments = @status
        @hdr.layout = 'post' unless @hdr.layout?
        $data = ["---\n"]
        for $key, $val of @hdr
          $data.push "#{$key}: #{$val}\n"
        $data.push "---\n"
        $data.push beautify(@content.html())

        if @filename is ''
          $date = @date.datepicker('getDate') ? new Date
          $mm = String($date.getMonth()+1)
          $dd = String($date.getDate())
          $yy = String($date.getFullYear())
          $dd = '0'+$dd if $dd.length is 1
          $mm = '0'+$mm if $mm.length is 1
          $slug = @title.text().toLowerCase().replace(/\s+/g, '-')
          @filename = "#{$yy}-#{$mm}-#{$dd}-#{$slug}.html"

        saveAs new Blob($data), @filename

      #
      # Add Tag Button Click Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @add.on 'click', ($e) =>
        unless @tag.val() is ''
          @selected.push @tag.val()
          @tags.push @tag.val()
          @tag.val ''
          @tags = @tags.sort()
          @setTags @selected

      #
      # Comments Status Change Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @comments.on 'change', ($e) =>
        @status = $e.target.value

    #
    # Set Tags
    #
    # @param  [Array<String>]  list of selected tags
    # @return [Void]
    #
    setTags: ($tags) ->

      $html = "<select data-placeholder=\"Select Tag\" multiple class=\"chosen-select\">"
      for $tag in @tags
        if $tags.indexOf($tag) is -1
          $html += "<option>#{$tag}</option>"
        else
          $html += "<option selected>#{$tag}</option>"

      $html += "</select>"

      @select.html $html
      @chosen = @select.find('.chosen-select')
      @chosen.css width: '400px'
      @chosen.chosen no_results_text: 'no match...'


      #
      # Selected Tags Change Event
      #
      # @param  [Event] e
      # @return [Void]
      #
      @chosen.chosen().change ($e) =>

        #
        # update the tags list
        #
        @selected = []
        for $option in $e.target
          if $option.selected
            @selected.push $option.label

