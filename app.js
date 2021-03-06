var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

$(function() {
  var Glitchtop;
  Glitchtop = (function() {
    function Glitchtop() {
      this.toggleLock = bind(this.toggleLock, this);
      this.initData();
      this.initElements();
      this.initCanvas();
      this.fillScreen();
      this.initUI();
      this.initEvents();
      this.initAnimation();
    }

    Glitchtop.prototype.initData = function() {
      var match;
      match = location.href.match(/(\d+)px&H\=(\d+)-(\d+)&S=(\d+)-(\d+)&L=(\d+)-(\d+)&P=(\d)&A=(\d)&I=(\d)/);
      if (match) {
        this.size = parseInt(match[1]);
        this.hue = {
          min: parseInt(match[2]),
          max: parseInt(match[3])
        };
        this.sat = {
          min: parseInt(match[4]),
          max: parseInt(match[5])
        };
        this.light = {
          min: parseInt(match[6]),
          max: parseInt(match[7])
        };
        this.pattern = parseInt(match[8]);
        this.animating = parseInt(match[9]);
        this["interface"] = parseInt(match[10]);
      } else {
        this.size = 40;
        this.hue = {
          min: 180,
          max: 230
        };
        this.sat = {
          min: 85,
          max: 100
        };
        this.light = {
          min: 40,
          max: 80
        };
        this.pattern = 1;
        this.animating = 0;
        this["interface"] = 1;
      }
      this.accent = (this.hue.max + this.hue.min) / 2;
      this.locks = {
        size: false,
        hue: false,
        sat: false,
        light: false,
        pattern: false,
        speed: true
      };
      this.max_size = 150;
      this.min_size = 10;
      this.min_speed = 20;
      this.max_speed = 300;
      this.speed = this.max_speed;
      this.mouse_moving = false;
      this.hovering_toggle_btn = false;
      return this.browser = !!window.chrome ? 'chrome' : 'notchrome';
    };

    Glitchtop.prototype.initCanvas = function() {
      this.view = {
        h: $(window).height(),
        w: $(window).width()
      };
      $("#canvas-holder").html("<canvas id=\"canvas\" width=\"" + this.view.w + "\" height=\"" + this.view.h + "\"></canvas>");
      this.canvas = document.getElementById("canvas");
      return this.ctx = this.canvas.getContext("2d");
    };

    Glitchtop.prototype.initEvents = function() {
      var count;
      this.shiftHeld = 0;
      $(document).keydown((function(_this) {
        return function(e) {
          if (e.shiftKey && !_this.shiftHeld) {
            return _this.shiftHeld = 1;
          }
        };
      })(this));
      $(document).keyup((function(_this) {
        return function(e) {
          switch (e.which) {
            case 32:
              _this.toggleAnimation();
              break;
            case 27:
              _this.toggleUI();
              break;
            case 83:
              _this.shuffle();
          }
          if (_this.shiftHeld) {
            _this.updateParams();
          }
          return _this.shiftHeld = 0;
        };
      })(this));
      $(document).mousemove((function(_this) {
        return function(e) {
          var xHue, ySat;
          if (_this.shiftHeld && (e.pageX % 5 === 1 || e.pageY % 5 === 1)) {
            xHue = ( ( e.pageX / _this.view.w ) * 360 ) | 0;
            ySat = 100 - ( ( (e.pageY / _this.view.h ) * 100 ) | 0 );
            _this.$el.sliderHue.dragslider({
              values: [xHue, xHue]
            });
            _this.$el.sliderSat.dragslider({
              values: [ySat, ySat]
            });
            _this.hue = {
              min: xHue,
              max: xHue
            };
            _this.sat = {
              min: ySat,
              max: ySat
            };
            return _this.fillScreen();
          }
        };
      })(this));
      $(window).mousemove((function(_this) {
        return function() {
          clearTimeout(_this.mouse_moving);
          _this.$el.btnToggle.fadeIn();
          return _this.mouse_moving = _this._setTimeout(500, function() {
            if (!(_this["interface"] === 1 || _this.hovering_toggle_btn)) {
              return _this.$el.btnToggle.fadeOut();
            }
          });
        };
      })(this));
      this.$el.btnToggle.mouseenter((function(_this) {
        return function() {
          return _this.hovering_toggle_btn = true;
        };
      })(this)).mouseleave((function(_this) {
        return function() {
          return _this.hovering_toggle_btn = false;
        };
      })(this));
      this.$el.downloadLink.click((function(_this) {
        return function(e) {
          e.target.download = _this.toFilename('png');
          return e.target.href = _this.canvas.toDataURL('image/png');
        };
      })(this));
      count = 0;
      return $(window).resize((function(_this) {
        return function() {
          if (count % 2 === 0) {
            _this.initCanvas();
            _this.fillScreen();
          }
          return count++;
        };
      })(this));
    };

    Glitchtop.prototype.initElements = function() {
      return this.$el = {
        uiData: $('.ui-data'),
        uiHolder: $('.ui-holder'),
        shareLinkHref: $('.share-link-href'),
        shareTwitter: $('.share-link-twitter'),
        sliderSize: $('#slider-size'),
        sliderHue: $('#slider-hue'),
        sliderSat: $('#slider-sat'),
        sliderLight: $('#slider-light'),
        sliderPattern: $('#slider-pattern'),
        sliderSpeed: $('#slider-speed'),
        btnAnimate: $('.btn-animate'),
        btnShuffle: $('.btn-shuffle'),
        btnCredits: $('.btn-credits'),
        btnKeyboard: $('.btn-keyboard'),
        btnShare: $('.btn-spread'),
        btnToggle: $('.btn-toggle'),
        dynamicColor: $('.dynamic-c'),
        dynamicBorder: $('.dynamic-c-border'),
        embedCode: $('.embed-code'),
        btn: $('.btn'),
        lock: $('.lock'),
        downloadLink: $('.download-link')
      };
    };

    Glitchtop.prototype.initUI = function() {
      var isQueued, that;
      isQueued = 0;
      this.$el.sliderSize.dragslider({
        value: this.size,
        rangeDrag: false,
        min: this.min_size,
        max: this.max_size,
        step: 10,
        slide: (function(_this) {
          return function(e, ui) {
            _this.size = ui.value;
            return _this.fillScreen();
          };
        })(this),
        change: (function(_this) {
          return function(e, ui) {
            if (!_this.shiftHeld) {
              return _this.updateParams();
            }
          };
        })(this)
      });
      this.$el.sliderHue.dragslider({
        range: true,
        rangeDrag: true,
        min: 0,
        max: 360,
        values: [this.hue.min, this.hue.max],
        slide: (function(_this) {
          return function(e, ui) {
            _this.hue.min = ui.values[0];
            _this.hue.max = ui.values[1];
            return _this.fillScreen();
          };
        })(this),
        change: (function(_this) {
          return function(e, ui) {
            if (!_this.shiftHeld) {
              return _this.updateParams();
            }
          };
        })(this)
      });
      this.$el.sliderSat.dragslider({
        range: true,
        rangeDrag: true,
        min: 0,
        max: 100,
        values: [this.sat.min, this.sat.max],
        slide: (function(_this) {
          return function(e, ui) {
            _this.sat.min = ui.values[0];
            _this.sat.max = ui.values[1];
            return _this.fillScreen();
          };
        })(this),
        change: (function(_this) {
          return function() {
            if (!_this.shiftHeld) {
              return _this.updateParams();
            }
          };
        })(this)
      });
      this.$el.sliderLight.dragslider({
        range: true,
        rangeDrag: true,
        min: 0,
        max: 100,
        values: [this.light.min, this.light.max],
        slide: (function(_this) {
          return function(e, ui) {
            _this.light.min = ui.values[0];
            _this.light.max = ui.values[1];
            return _this.fillScreen();
          };
        })(this),
        change: (function(_this) {
          return function() {
            if (!_this.shiftHeld) {
              return _this.updateParams();
            }
          };
        })(this)
      });
      this.$el.sliderSpeed.dragslider({
        value: this.max_speed - this.speed + this.min_speed,
        rangeDrag: false,
        min: this.min_speed,
        max: this.max_speed,
        step: 10,
        slide: (function(_this) {
          return function(e, ui) {
            _this.speed = _this.max_speed - ui.value + _this.min_speed;
            if (_this.animating != null) {
              _this.stopAnimation();
              return _this.startAnimation();
            }
          };
        })(this),
        start: (function(_this) {
          return function() {
            if (!_this.animating) {
              _this.startAnimation();
              return isQueued = 1;
            }
          };
        })(this),
        stop: (function(_this) {
          return function() {
            if (_this.animating && isQueued) {
              _this.stopAnimation();
              return isQueued = 0;
            }
          };
        })(this)
      });
      this.$el.sliderPattern.dragslider({
        value: this.pattern,
        rangeDrag: false,
        min: 1,
        max: 4,
        step: 1,
        slide: (function(_this) {
          return function(e, ui) {
            _this.pattern = ui.value;
            return _this.fillScreen();
          };
        })(this),
        change: (function(_this) {
          return function(e, ui) {
            return _this.updateParams();
          };
        })(this)
      });
      this.$el.btnAnimate.click((function(_this) {
        return function(e) {
          _this.toggleAnimation();
          return e.stopPropagation();
        };
      })(this));
      that = this;
      this.$el.btnShuffle.click(function(e) {
        that.shuffle();
        $(this).css({
          color: "hsl(" + this.accent + ", 80%, 70%)"
        });
        return e.stopPropagation();
      });
      this.$el.btnCredits.click((function(_this) {
        return function(e) {
          _this.toggleVisibility('credits');
          return e.stopPropagation();
        };
      })(this));
      this.$el.btnKeyboard.click((function(_this) {
        return function(e) {
          _this.toggleVisibility('keyboard');
          return e.stopPropagation();
        };
      })(this));
      this.$el.btnShare.click((function(_this) {
        return function(e) {
          _this.toggleVisibility('spread');
          return e.stopPropagation();
        };
      })(this));
      this.$el.btnToggle.click((function(_this) {
        return function(e) {
          _this.toggleUI();
          return e.stopPropagation();
        };
      })(this));
      this.updateLockStates();
      this.$el.lock.click(this.toggleLock);
      if (this.browser !== 'chrome') {
        this.$el.downloadLink.html('right click here and save');
      }
      if (this["interface"] === 1) {
        return this.$el.uiHolder.show();
      } else {
        this.$el.btnToggle.text('+');
        return this.$el.btnToggle.fadeOut();
      }
    };

    Glitchtop.prototype.initAnimation = function() {
      if (this.animating) {
        return this.startAnimation();
      }
    };

    Glitchtop.prototype.startAnimation = function() {
      this.animating = 1;
      this.animatingInt = setInterval((function(_this) {
        return function() {
          _this.fillScreen();
          return true;
        };
      })(this), this.speed);
      return this.$el.btnAnimate.html('<i class="icon-pause"></i>');
    };

    Glitchtop.prototype.stopAnimation = function() {
      this.animating = 0;
      try {
        clearInterval(this.animatingInt);
      } catch (undefined) {}
      return this.$el.btnAnimate.html('<i class="icon-play"></i>');
    };

    Glitchtop.prototype.toggleAnimation = function() {
      if (this.animating) {
        this.stopAnimation();
      } else {
        this.startAnimation();
      }
      return this.updateParams();
    };

    Glitchtop.prototype.fillScreen = function() {
      if (this.size < 20) {
        this.draw(4);
      } else if (this.size < 50) {
        this.draw(2);
      } else {
        this.draw(1);
      }
      this.updateUIdata();
      return this.changeUIColor();
    };

    Glitchtop.prototype.draw = function(d) {
      var h, s, w;
      d = d * this.pattern;
      s = this.size;
      w = Math.floor(Math.floor(this.view.w / this.size) / d) + 1;
      h = Math.floor(Math.floor(this.view.h / this.size) / d) + 1;
      for ( var x = 0; x < w; x++ ) {
        for ( var y = 0; y < h; y++ ) {
          this.ctx.fillStyle = this.genColor();
          for ( var a = (d-1); a >= 0; a-- ) {
            for ( var b = (d-1); b >= 0; b-- ) {
              this.ctx.fillRect( (x+w*a)*s, (y+h*b)*s, s, s);
            }
          }
        }
      };
      return true;
    };

    Glitchtop.prototype.shuffle = function() {
      if (this.randomize() === false) {
        return;
      }
      this.updateParams();
      this.updateUIsliders();
      return this.fillScreen();
    };

    Glitchtop.prototype.randomize = function() {
      var changed, ref, ref1, ref2;
      changed = false;
      if (!this.locks.size) {
        this.size = Math.round(this._rand(this.min_size, this.max_size) / 10) * 10;
        changed = true;
      }
      if (!this.locks.hue) {
        this.hue = {
          min: this._rand(0, 360),
          max: this._rand(0, 360)
        };
        if (this.hue.max < this.hue.min) {
          ref = [this.hue.max, this.hue.min], this.hue.min = ref[0], this.hue.max = ref[1];
        }
        changed = true;
      }
      if (!this.locks.sat) {
        this.sat = {
          min: this._rand(0, 60),
          max: this._rand(50, 100)
        };
        if (this.sat.max < this.sat.min) {
          ref1 = [this.sat.max, this.sat.min], this.sat.min = ref1[0], this.sat.max = ref1[1];
        }
        changed = true;
      }
      if (!this.locks.light) {
        this.light = {
          min: this._rand(0, 60),
          max: this._rand(50, 100)
        };
        if (this.light.max < this.light.min) {
          ref2 = [this.light.max, this.light.min], this.light.min = ref2[0], this.light.max = ref2[1];
        }
        changed = true;
      }
      return changed;
    };

    Glitchtop.prototype.toggleVisibility = function(cl) {
      var $info;
      this.$el.btn.removeClass('dynamic-c').removeAttr('style');
      $info = $('.' + cl);
      if ($info.is(":visible")) {
        return $info.hide();
      } else {
        $('.btn-' + cl).addClass('dynamic-c').css({
          color: "hsl(" + this.accent + ", 80%, 70%)"
        });
        $('.info').hide();
        return $info.show();
      }
    };

    Glitchtop.prototype.toggleUI = function() {
      if (this.$el.uiHolder.is(':visible')) {
        this.$el.uiHolder.fadeOut();
        this["interface"] = 0;
        return this.$el.btnToggle.text('+');
      } else {
        this.$el.uiHolder.fadeIn();
        this["interface"] = 1;
        return this.$el.btnToggle.text('-');
      }
    };

    Glitchtop.prototype.changeUIColor = function() {
      this.accent = (this.hue.min + this.hue.max) / 2;
      $('.dynamic-c').css({
        color: "hsl(" + this.accent + ", 80%, 70%)"
      });
      return this.$el.dynamicBorder.css({
        'border-color': "hsl(" + this.accent + ", 80%, 70%)"
      });
    };

    Glitchtop.prototype.genColor = function(hue, sat, light) {
      var h, l, s;
      h = hue != null ? hue : this._rand(this.hue.min, this.hue.max);
      s = sat != null ? sat : this._rand(this.sat.min, this.sat.max);
      l = light != null ? light : this._rand(this.light.min, this.light.max);
      return "hsl(" + h + "," + s + "%," + l + "%)";
    };

    Glitchtop.prototype.updateParams = function() {
      this.updateURL();
      return this.updateUIdata();
    };

    Glitchtop.prototype.toggleLock = function(e) {
      var param, state;
      param = $(e.currentTarget).data('param');
      state = this.locks[param];
      if (state) {
        return this.setLockState(param, false);
      } else {
        return this.setLockState(param, true);
      }
    };

    Glitchtop.prototype.updateLockStates = function() {
      var key, ref, results, val;
      ref = this.locks;
      results = [];
      for (key in ref) {
        val = ref[key];
        results.push(this.setLockState(key, val));
      }
      return results;
    };

    Glitchtop.prototype.setLockState = function(param, state) {
      this.locks[param] = state;
      if (state) {
        return $(".lock-" + param + " i").attr('class', 'icon-lock');
      } else {
        return $(".lock-" + param + " i").attr('class', 'icon-lock-open');
      }
    };

    Glitchtop.prototype.updateURL = function() {
      if (this.browser === 'chrome') {
        return location.replace('#' + this.toParams());
      } else {
        return location.hash = '';
      }
    };

    Glitchtop.prototype.updateUIdata = function() {
      var link;
      link = location.origin + '#' + this.toParams();
      this.$el.uiData.html(this.toStr());
      this.$el.shareLinkHref.attr('href', link);
      this.$el.shareTwitter.attr('href', "http://twitter.com/home?status=I made this with %23glitchtop " + encodeURIComponent(link));
      return this.$el.embedCode.text(this.toEmbed());
    };

    Glitchtop.prototype.updateUIsliders = function() {
      this.$el.sliderSize.dragslider({
        value: this.size
      });
      this.$el.sliderHue.dragslider({
        values: [this.hue.min, this.hue.max]
      });
      this.$el.sliderSat.dragslider({
        values: [this.sat.min, this.sat.max]
      });
      this.$el.sliderLight.dragslider({
        values: [this.light.min, this.light.max]
      });
      return this.$el.sliderPattern.dragslider({
        value: this.pattern
      });
    };

    Glitchtop.prototype.toParams = function() {
      return this.size + "px&H=" + this.hue.min + "-" + this.hue.max + "&S=" + this.sat.min + "-" + this.sat.max + "&L=" + this.light.min + "-" + this.light.max + "&P=" + this.pattern + "&A=" + this.animating + "&I=" + this["interface"];
    };

    Glitchtop.prototype.toStr = function() {
      return this.size + "px, H=" + this.hue.min + "-" + this.hue.max + ", S=" + this.sat.min + "-" + this.sat.max + ", L=" + this.light.min + "-" + this.light.max;
    };

    Glitchtop.prototype.toEmbed = function() {
      return "<iframe src=\"http://chrisfoley.github.io/glitchtop/#" + (this.toParams()) + "\">";
    };

    Glitchtop.prototype.toFilename = function(ext) {
      return "Glitchtop_" + this.size + "px_H" + this.hue.min + "-" + this.hue.max + "_S" + this.sat.min + "-" + this.sat.max + "_L" + this.light.min + "-" + this.light.max + "." + ext;
    };

    Glitchtop.prototype._rand = function(min, max) {
      return Math.floor(Math.random() * (max - min + 1)) + min;
    };

    Glitchtop.prototype._setTimeout = function(time, func) {
      return window.setTimeout(func, time);
    };

    return Glitchtop;

  })();
  return window.Glitchtop = new Glitchtop;
});
