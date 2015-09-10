$ ->
  class Glitchtop
    constructor: ->
      @initData()
      @initElements()
      @initCanvas()
      @fillScreen()
      @initUI()
      @initEvents()
      @initAnimation()

    initData: ->
      match = location.href.match ///
        (\d+)px
        &H\=(\d+)-(\d+)
        &S=(\d+)-(\d+)
        &L=(\d+)-(\d+)
        &P=(\d)
        &A=(\d)
        &I=(\d)
      ///

      if match
        # console.log 'PARAMS:', match
        @size = parseInt match[1]
        @hue =
          min: parseInt match[2]
          max: parseInt match[3]
        @sat =
          min: parseInt match[4]
          max: parseInt match[5]
        @light =
          min: parseInt match[6]
          max: parseInt match[7]
        @pattern = parseInt match[8]
        @animating = parseInt match[9]
        @interface = parseInt match[10]
      else
        # console.log 'DEFAULT'
        @size = 40
        @hue =
          min: 180
          max: 230
        @sat =
          min: 85
          max: 100
        @light =
          min: 40
          max: 80
        @pattern = 1
        @animating = 0
        @interface = 1

      @accent = ( @hue.max + @hue.min ) / 2

      @locks =
        size: false
        hue: false
        sat: false
        light: false
        pattern: false
        speed: true

      @max_size = 150
      @min_size = 10
      @min_speed = 20
      @max_speed = 300
      @speed = @max_speed

      @mouse_moving = false
      @hovering_toggle_btn = false

      @browser = if !!window.chrome then 'chrome' else 'notchrome'

    initCanvas: ->
      @view =
        h: $(window).height()
        w: $(window).width()
      $("#canvas-holder").html "<canvas id=\"canvas\" width=\"#{@view.w}\" height=\"#{@view.h}\"></canvas>"
      @canvas = document.getElementById("canvas")
      @ctx = @canvas.getContext("2d")

    initEvents: ->
      
      # KEY EVENTS

      @shiftHeld = 0
      $(document).keydown (e) =>
        @shiftHeld = 1 if e.shiftKey and not @shiftHeld

      $(document).keyup (e) =>
        switch e.which
          when 32 then @toggleAnimation()
          when 27 then @toggleUI()
          when 83 then @shuffle()
        @updateParams() if @shiftHeld
        @shiftHeld = 0

      # MOUSE EVENTS

      # mouse move + shift: fill screen with color based on mouse position
      $(document).mousemove (e) =>
        if @shiftHeld and ( e.pageX % 5 is 1 or e.pageY % 5 is 1 )
          xHue = `( ( e.pageX / _this.view.w ) * 360 ) | 0`
          ySat = `100 - ( ( (e.pageY / _this.view.h ) * 100 ) | 0 )`
          @$el.sliderHue.dragslider values: [ xHue, xHue ]
          @$el.sliderSat.dragslider values: [ ySat, ySat ]
          @hue = min: xHue, max: xHue
          @sat = min: ySat, max: ySat
          @fillScreen()

      # toggle animation on window click
      # $(document).click (e) =>
      #   @toggleAnimation() if $(e.target).closest('.ui-holder').length is 0

      # fade in toggle button on mouse move
      $(window)
        .mousemove =>
          clearTimeout @mouse_moving
          @$el.btnToggle.fadeIn()
          @mouse_moving = @_setTimeout 500, =>
            unless @interface is 1 or @hovering_toggle_btn
              @$el.btnToggle.fadeOut() 

      # track if mouse is over toggle button
      @$el.btnToggle
        .mouseenter =>
          @hovering_toggle_btn = true
        .mouseleave =>
          @hovering_toggle_btn = false
        
      # on click of download link
      @$el.downloadLink.click (e) =>
        e.target.download = @toFilename 'png'
        e.target.href = @canvas.toDataURL 'image/png'

      # WINDOW EVENTS

      count = 0
      $(window).resize =>
        # don't fire every time while resizing
        if count % 2 is 0
          @initCanvas()
          @fillScreen()
        count++

    initElements: ->
      @$el =
        uiData:        $('.ui-data')
        uiHolder:      $('.ui-holder')
        shareLinkHref: $('.share-link-href')
        shareTwitter:  $('.share-link-twitter')
        sliderSize:    $('#slider-size')
        sliderHue:     $('#slider-hue')
        sliderSat:     $('#slider-sat')
        sliderLight:   $('#slider-light')
        sliderPattern: $('#slider-pattern')
        sliderSpeed:   $('#slider-speed')
        btnAnimate:    $('.btn-animate')
        btnShuffle:    $('.btn-shuffle')
        btnCredits:    $('.btn-credits')
        btnKeyboard:   $('.btn-keyboard')
        btnShare:      $('.btn-spread')
        btnToggle:     $('.btn-toggle')
        dynamicColor:  $('.dynamic-c')
        dynamicBorder: $('.dynamic-c-border')
        embedCode:     $('.embed-code')
        btn:           $('.btn')
        lock:          $('.lock')
        downloadLink:  $('.download-link')

    initUI: ->
      isQueued = 0

      @$el.sliderSize.dragslider
        value: @size
        rangeDrag: false
        min: @min_size
        max: @max_size
        step: 10
        slide: (e, ui) =>
          @size = ui.value
          @fillScreen()
        change: (e, ui) =>
          @updateParams()  unless @shiftHeld

      @$el.sliderHue.dragslider
        range: true
        rangeDrag: true
        min: 0
        max: 360
        values: [@hue.min, @hue.max]
        slide: (e, ui) =>
          @hue.min = ui.values[0]
          @hue.max = ui.values[1]
          @fillScreen()
        change: (e, ui) =>
          @updateParams()  unless @shiftHeld

      @$el.sliderSat.dragslider
        range: true
        rangeDrag: true
        min: 0
        max: 100
        values: [@sat.min, @sat.max]
        slide: (e, ui) =>
          @sat.min = ui.values[0]
          @sat.max = ui.values[1]
          @fillScreen()
        change: =>
          @updateParams()  unless @shiftHeld

      @$el.sliderLight.dragslider
        range: true
        rangeDrag: true
        min: 0
        max: 100
        values: [@light.min, @light.max]
        slide: (e, ui) =>
          @light.min = ui.values[0]
          @light.max = ui.values[1]
          @fillScreen()
        change: =>
          @updateParams()  unless @shiftHeld

      @$el.sliderSpeed.dragslider
        value: @max_speed - @speed + @min_speed
        rangeDrag: false
        min: @min_speed
        max: @max_speed
        step: 10
        slide: (e, ui) =>
          # update speed while sliding
          @speed = @max_speed - ui.value + @min_speed
          if @animating?
            @stopAnimation()
            @startAnimation()
        start: =>
          # animate while sliding
          if not @animating
            @startAnimation()
            isQueued = 1
        stop: =>
          # only stop if wasn't animating before slide began
          if @animating and isQueued
            @stopAnimation()
            isQueued = 0

      @$el.sliderPattern.dragslider
        value: @pattern
        rangeDrag: false
        min: 1
        max: 4
        step: 1
        slide: (e, ui) =>
          @pattern = ui.value
          @fillScreen()
        change: (e, ui) =>
          @updateParams()

      @$el.btnAnimate.click (e) =>
        @toggleAnimation()
        e.stopPropagation()

      that = @
      @$el.btnShuffle.click (e) ->
        that.shuffle()
        $(this).css color: "hsl(#{@accent}, 80%, 70%)"
        e.stopPropagation()

      @$el.btnCredits.click (e) =>
        @toggleVisibility 'credits'
        e.stopPropagation()

      @$el.btnKeyboard.click (e) =>
        @toggleVisibility 'keyboard'
        e.stopPropagation()

      @$el.btnShare.click (e) =>
        @toggleVisibility 'spread'
        e.stopPropagation()

      @$el.btnToggle.click (e) =>
        @toggleUI()
        e.stopPropagation()

      # lock state
      @updateLockStates()
      @$el.lock.click @toggleLock

      unless @browser is 'chrome'
        @$el.downloadLink.html 'right click here and save'
      
      # show or hide UI
      if @interface is 1
        @$el.uiHolder.show()
      else
        @$el.btnToggle.text '+'
        @$el.btnToggle.fadeOut() 

    initAnimation: ->
      @startAnimation() if @animating

    startAnimation: ->
      @animating = 1
      @animatingInt = setInterval( =>
        @fillScreen()
        true
      , @speed )
      @$el.btnAnimate.html '<i class="icon-pause"></i>'

    stopAnimation: ->
      @animating = 0
      try clearInterval @animatingInt
      @$el.btnAnimate.html '<i class="icon-play"></i>'

    toggleAnimation: ->
      if @animating
        @stopAnimation()
      else
        @startAnimation()
      @updateParams()

    fillScreen: ->
      if @size < 20
        @draw(4)
      else if @size < 50
        @draw(2)
      else
        @draw(1)
      @updateUIdata()
      @changeUIColor()

    draw: (d) ->
      # d is 1 means no mirrored subdivisions, maximum randomness
      # w & h are num of sqaures to fill screen at this sqaure size and # of mirrored subdivisions
      d = d * @pattern
      s = @size
      w = Math.floor( Math.floor(@view.w / @size) / d ) + 1
      h = Math.floor( Math.floor(@view.h / @size) / d ) + 1

      `for ( var x = 0; x < w; x++ ) {
        for ( var y = 0; y < h; y++ ) {
          this.ctx.fillStyle = this.genColor();
          for ( var a = (d-1); a >= 0; a-- ) {
            for ( var b = (d-1); b >= 0; b-- ) {
              this.ctx.fillRect( (x+w*a)*s, (y+h*b)*s, s, s);
            }
          }
        }
      }`
      true

    shuffle: ->
      return if @randomize() is false
      @updateParams()
      @updateUIsliders()
      @fillScreen()

    randomize: ->
      changed = false

      unless @locks.size
        @size = Math.round( @_rand(@min_size, @max_size) / 10 ) * 10
        changed = true
      unless @locks.hue
        @hue = min: @_rand(0,360), max: @_rand(0,360)
        [@hue.min, @hue.max] = [@hue.max, @hue.min] if @hue.max < @hue.min
        changed = true
      unless @locks.sat
        @sat = min: @_rand(0,60), max: @_rand(50,100)
        [@sat.min, @sat.max] = [@sat.max, @sat.min] if @sat.max < @sat.min
        changed = true
      unless @locks.light
        @light = min: @_rand(0,60), max: @_rand(50,100)
        [@light.min, @light.max] = [@light.max, @light.min] if @light.max < @light.min
        changed = true
      changed

    toggleVisibility: (cl) ->
      # remove accent color from btn
      @$el.btn.removeClass('dynamic-c').removeAttr('style')

      $info = $('.' + cl)
      if $info.is(":visible")
        $info.hide()
      else
        # add accent color to currently active button
        $('.btn-' + cl).addClass('dynamic-c').css color: "hsl(#{@accent}, 80%, 70%)"
        $('.info').hide()
        $info.show()

    toggleUI: ->
      if @$el.uiHolder.is(':visible')
        @$el.uiHolder.fadeOut()
        @interface = 0
        @$el.btnToggle.text '+'
      else
        @$el.uiHolder.fadeIn()
        @interface = 1
        @$el.btnToggle.text '-'

    changeUIColor: ->
      @accent = ( @hue.min + @hue.max ) / 2
      $('.dynamic-c').css color: "hsl(#{@accent}, 80%, 70%)"
      @$el.dynamicBorder.css 'border-color': "hsl(#{@accent}, 80%, 70%)"

    genColor: (hue, sat, light) ->
      h = hue ? @_rand( @hue.min, @hue.max )
      s = sat ? @_rand( @sat.min, @sat.max )
      l = light ? @_rand( @light.min, @light.max )
      "hsl(#{h},#{s}%,#{l}%)"

    updateParams: ->
      @updateURL()
      @updateUIdata()

    toggleLock: (e) =>
      param = $(e.currentTarget).data 'param'
      state = @locks[param]

      if state
        @setLockState param, false
      else
        @setLockState param, true

    updateLockStates: ->
      for key, val of @locks
        @setLockState key, val

    setLockState: (param, state) ->
      @locks[param] = state
      if state
        $(".lock-#{param} i").attr 'class', 'icon-lock'
      else
        $(".lock-#{param} i").attr 'class', 'icon-lock-open'

    updateURL: ->
      if @browser is 'chrome'
        location.replace '#' + @toParams()
      else
        location.hash = ''

    updateUIdata: ->
      link = location.origin + '#' + @toParams()
      @$el.uiData.html @toStr()
      @$el.shareLinkHref.attr 'href', link
      @$el.shareTwitter.attr 'href', "http://twitter.com/home?status=I made this with %23glitchtop " + encodeURIComponent(link)
      @$el.embedCode.text @toEmbed()

    updateUIsliders: ->
      @$el.sliderSize.dragslider value: @size
      @$el.sliderHue.dragslider values: [@hue.min, @hue.max ]
      @$el.sliderSat.dragslider values: [ @sat.min, @sat.max ]
      @$el.sliderLight.dragslider values: [ @light.min, @light.max ]
      @$el.sliderPattern.dragslider value: @pattern

    toParams: -> "#{@size}px&H=#{@hue.min}-#{@hue.max}&S=#{@sat.min}-#{@sat.max}&L=#{@light.min}-#{@light.max}&P=#{@pattern}&A=#{@animating}&I=#{@interface}"

    toStr: -> "#{@size}px, H=#{@hue.min}-#{@hue.max}, S=#{@sat.min}-#{@sat.max}, L=#{@light.min}-#{@light.max}"

    toEmbed: -> """<iframe src="http://chrisfoley.github.io/glitchtop/##{@toParams()}">"""
    
    toFilename: (ext) -> "Glitchtop_#{@size}px_H#{@hue.min}-#{@hue.max}_S#{@sat.min}-#{@sat.max}_L#{@light.min}-#{@light.max}.#{ext}"

    _rand: (min, max) -> Math.floor( Math.random() * (max - min + 1) ) + min

    _setTimeout: (time, func) -> window.setTimeout func, time

  window.Glitchtop = new Glitchtop
