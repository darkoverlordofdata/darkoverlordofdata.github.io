// Generated by CoffeeScript 1.6.3
(function() {
  (function($, window, document) {
    var Muninn;
    $.prototype.muninn = function($options) {
      var _ref;
      if ($options == null) {
        $options = {};
      }
      return (_ref = $.data(this, 'muninn')) != null ? _ref : $.data(this, 'muninn', new Muninn(this, $options));
    };
    return Muninn = (function() {
      var chosen, path, saveAs, yaml;

      path = require('path');

      yaml = require('yaml-js');

      saveAs = require('./FileSaver');

      chosen = require('chosen-jquery-browserify');

      Muninn.prototype["default"] = {
        title: 'Title',
        date: 'd MM, yy',
        tags: '#tag-cloud'
      };

      Muninn.prototype.options = null;

      Muninn.prototype.selected = null;

      Muninn.prototype.tags = null;

      Muninn.prototype.filename = '';

      Muninn.prototype.status = 'none';

      Muninn.prototype.hdr = null;

      Muninn.prototype.title = null;

      Muninn.prototype.date = null;

      Muninn.prototype.content = null;

      Muninn.prototype.chosen = null;

      Muninn.prototype.file = null;

      Muninn.prototype.save = null;

      Muninn.prototype.load = null;

      Muninn.prototype.select = null;

      Muninn.prototype.tag = null;

      Muninn.prototype.add = null;

      Muninn.prototype.comments = null;

      function Muninn($container, $options) {
        var $tag, _i, _len, _ref,
          _this = this;
        this.options = $.extend(this["default"], $options);
        this.tags = [];
        _ref = $(this.options.tags).text().split(/\s+/).sort();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          $tag = _ref[_i];
          if ($tag !== '') {
            this.tags.push($tag);
          }
        }
        $container.html("<div class=\"span12\">\n  <h1 class=\"muninn-title\"></h1>\n  <input class=\"muninn-date muted\" type=\"text\" placeholder=\"Enter Date\" />\n  <div class=\"muninn-content\"></div>\n  <br />\n</div>\n<div class=\"well span7\">\n  <div class=\"muninn-select\"></div>\n  <div class=\"input-append\">\n    <input placeholder=\"Ener new tag\" class=\"muninn-tag span6\" type=\"text\">\n    <button class=\"muninn-add btn\" type=\"button\"><i class=\"icon icon-tag\"> </i></button>\n  </div>\n  <label class=\"radio\">\n    <input class=\"muninn-comments\" name=\"muninn-comments\" id=\"muninn-comments-none\" type=\"radio\" value=\"none\" checked> Comments are not enabled\n  </label>\n  <label class=\"radio\">\n    <input class=\"muninn-comments\" name=\"muninn-comments\" id=\"muninn-comments-open\" type=\"radio\" value=\"open\"> Comments are Open\n  </label>\n  <label class=\"radio\">\n    <input class=\"muninn-comments\" name=\"muninn-comments\" id=\"muninn-comments-closed\" type=\"radio\" value=\"closed\"> Comments are Closed\n  </label>\n  <div class=\"span6\"></div>\n  <div class=\"btn-group\">\n  <a class=\"muninn-load btn btn-primary\"><i class=\"icon icon-upload icon-white\"> </i> Load...</a>\n  <a class=\"muninn-save btn\"><i class=\"icon icon-download\"> </i> Save...</a>\n  </div>\n  <input class=\"muninn-file hidden\" type=\"file\" />\n</div>");
        this.title = $container.find('.muninn-title');
        this.date = $container.find('.muninn-date');
        this.content = $container.find('.muninn-content');
        this.select = $container.find('.muninn-select');
        this.tag = $container.find('.muninn-tag');
        this.add = $container.find('.muninn-add');
        this.comments = $container.find('.muninn-comments');
        this.file = $container.find('.muninn-file');
        this.load = $container.find('.muninn-load');
        this.save = $container.find('.muninn-save');
        this.title.html(this.options.title);
        tinymce.init({
          selector: '.muninn-title',
          inline: true,
          menubar: false,
          toolbar: 'undo redo'
        });
        this.date.datepicker({
          dateFormat: this.options.date
        });
        this.content.html("<div class=\"muted\">\n<p>Use this page to edit or create new posts. Create a new post,\nor select a post to edit from your _posts or _drafts folder.</p>\n<p>To update your site with your changes, use either:</p>\n<code>$ huginn build</code>\n<p>or</p>\n<code>$ jekyll build</code>\n</div>");
        tinymce.init({
          selector: '.muninn-content',
          inline: true,
          menubar: false,
          plugins: ['advlist autolink autosave link image lists charmap print preview hr anchor pagebreak spellchecker', 'searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking', 'table contextmenu directionality emoticons template textcolor paste fullpage textcolor'],
          toolbar1: 'newdocument fullpage | bold italic underline strikethrough | alignleft aligncenter alignright alignjustify | styleselect formatselect fontselect fontsizeselect',
          toolbar2: 'cut copy paste | searchreplace | bullist numlist | outdent indent blockquote | undo redo | link unlink anchor image media code | inserttime preview | forecolor backcolor',
          toolbar3: 'table | hr removeformat | subscript superscript | charmap emoticons | print fullscreen | ltr rtl | spellchecker | visualchars visualblocks nonbreaking template pagebreak restoredraft'
        });
        this.selected = [];
        this.setTags(this.selected);
        this.file.on('change', function($e) {
          var $file, reader;
          $file = $e.target.files[0];
          if (!/\.html$/.test($file.name) && !/\.md$/.test($file.name)) {
            return alert('Invalid Filetype');
          }
          reader = new FileReader;
          reader.onload = (function($file) {
            return function($e) {
              var $buf, $dd, $ext, $mm, $name, $seg, $yy, _ref1, _ref2, _ref3, _ref4;
              $buf = $e.target.result;
              _this.hdr = {};
              if ($buf.slice(0, 4) === '---\n') {
                $buf = $buf.split('---\n');
                _this.hdr = yaml.load($buf[1]);
                $buf = $buf[2];
              }
              $ext = path.extname($file.name);
              $name = path.basename($file.name, $ext);
              $seg = $name.split('-');
              $yy = $seg.shift();
              $mm = $seg.shift();
              $dd = $seg.shift();
              _this.content.html($buf);
              _this.title.html(_this.hdr.title);
              _this.date.datepicker('setDate', new Date($yy, $mm - 1, $dd));
              _this.filename = $file.name;
              _this.selected = (_ref1 = (_ref2 = _this.hdr) != null ? _ref2.tags.split(' ') : void 0) != null ? _ref1 : [];
              _this.comments = (_ref3 = (_ref4 = _this.hdr) != null ? _ref4.comments : void 0) != null ? _ref3 : 'none';
              $container.find('#muninn-comments-' + _this.comments).prop('checked', true);
              return _this.setTags(_this.selected);
            };
          })($file);
          return reader.readAsBinaryString($file);
        });
        this.load.on('click', function($e) {
          return _this.file.get(0).click();
        });
        this.save.on('click', function($e) {
          var $data, $date, $dd, $key, $mm, $slug, $val, $yy, _ref1, _ref2;
          if (_this.hdr == null) {
            _this.hdr = {};
          }
          _this.hdr.title = _this.title.html();
          _this.hdr.tags = _this.selected.join(' ');
          _this.hdr.comments = _this.status;
          $data = ["---\n"];
          _ref1 = _this.hdr;
          for ($key in _ref1) {
            $val = _ref1[$key];
            $data.push("" + $key + ": " + $val + "\n");
          }
          $data.push("---\n");
          $data.push(_this.content.html());
          if (_this.filename === '') {
            $date = (_ref2 = _this.date.datepicker('getDate')) != null ? _ref2 : new Date;
            $mm = String($date.getMonth() + 1);
            $dd = String($date.getDate());
            $yy = String($date.getFullYear());
            if ($dd.length === 1) {
              $dd = '0' + $dd;
            }
            if ($mm.length === 1) {
              $mm = '0' + $mm;
            }
            $slug = _this.title.html().toLowerCase().replace(/\s+/g, '-');
            _this.filename = "" + $yy + "-" + $mm + "-" + $dd + "-" + $slug + ".html";
          }
          return saveAs(new Blob($data), _this.filename);
        });
        this.add.on('click', function($e) {
          if (_this.tag.val() !== '') {
            _this.selected.push(_this.tag.val());
            _this.tags.push(_this.tag.val());
            _this.tag.val('');
            _this.tags = _this.tags.sort();
            return _this.setTags(_this.selected);
          }
        });
        this.comments.on('change', function($e) {
          return _this.status = $e.target.value;
        });
      }

      Muninn.prototype.setTags = function($tags) {
        var $html, $tag, _i, _len, _ref,
          _this = this;
        $html = "<select data-placeholder=\"Select Tag\" multiple class=\"chosen-select\">";
        _ref = this.tags;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          $tag = _ref[_i];
          if ($tags.indexOf($tag) === -1) {
            $html += "<option>" + $tag + "</option>";
          } else {
            $html += "<option selected>" + $tag + "</option>";
          }
        }
        $html += "</select>";
        this.select.html($html);
        this.chosen = this.select.find('.chosen-select');
        this.chosen.css({
          width: '400px'
        });
        this.chosen.chosen({
          no_results_text: 'no match...'
        });
        return this.chosen.chosen().change(function($e) {
          var $option, _j, _len1, _ref1, _results;
          _this.selected = [];
          _ref1 = $e.target;
          _results = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            $option = _ref1[_j];
            if ($option.selected) {
              _results.push(_this.selected.push($option.label));
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        });
      };

      return Muninn;

    })();
  })(jQuery, window, document);

}).call(this);
