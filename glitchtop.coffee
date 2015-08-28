# TODO
# • button to show UI that's visible when mouse is moving
# • save as image

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
      if m = location.href.match /(\d+)px&H\=(\d+)-(\d+)&S=(\d+)-(\d+)&L=(\d+)-(\d+)&P=(\d)&A=(\d)&I=(\d)$/
        @size = parseInt m[1]
        @hue =
          min: parseInt m[2]
          max: parseInt m[3]
        @sat =
          min: parseInt m[4]
          max: parseInt m[5]
        @light =
          min: parseInt m[6]
          max: parseInt m[7]
        @pattern = parseInt m[8]
        @animating = parseInt m[9]
        @interface = parseInt m[10]
        @speed = 70
      else
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
        @speed = 30
        @interface = 1

      @accent = ( @hue.max + @hue.min ) / 2

      @locks =
        size: false
        hue: false
        sat: false
        light: false
        pattern: true
        speed: true

    initCanvas: ->
      @view =
        h: $(window).height()
        w: $(window).width()
      $("#canvas-holder").html "<canvas id=\"canvas\" width=\"#{@view.w}\" height=\"#{@view.h}\"></canvas>"
      @canvas = document.getElementById("canvas")
      @ctx = @canvas.getContext("2d")

    initEvents: ->
      # key events
      @shiftHeld = 0
      $(document).keydown (e) =>
        @shiftHeld = 1 if e.shiftKey and not @shiftHeld

      $(document).keyup (e) =>
        switch e.which
          when 13 then @shuffle()
          when 32 then @toggleAnimation()
          when 27 then @toggleUI()
        @updateParams() if @shiftHeld
        @shiftHeld = 0

      # mouse events
      $(document).mousemove (e) =>
        # shift held: fill screen with color based on mouse position
        if @shiftHeld and ( e.pageX % 5 is 1 or e.pageY % 5 is 1 )
          xHue = `( ( e.pageX / _this.view.w ) * 360 ) | 0`
          ySat = `100 - ( ( (e.pageY / _this.view.h ) * 100 ) | 0 )`
          @$el.sliderHue.dragslider values: [ xHue, xHue ]
          @$el.sliderSat.dragslider values: [ ySat, ySat ]
          @hue = min: xHue, max: xHue
          @sat = min: ySat, max: ySat
          @fillScreen()

      $(document).click (e) =>
        @toggleAnimation() if $(e.target).closest('.ui-holder').length is 0

      # window events
      count = 0
      $(window).resize =>
        # don't fire every time while resizing
        if count % 2 is 0
          @initCanvas()
          @fillScreen()
        count++

    initElements: ->
      @$el =
        uiData: $('.ui-data')
        uiHolder: $('.ui-holder')
        shareLinkHref: $('.share-link-href')
        shareLinkTwitter: $('.share-link-twitter')
        sliderSize: $('#slider-size')
        sliderHue: $('#slider-hue')
        sliderSat: $('#slider-sat')
        sliderLight: $('#slider-light')
        sliderPattern: $('#slider-pattern')
        sliderSpeed: $('#slider-speed')
        btnAnimate: $('.btn-animate')
        btnShuffle: $('.btn-shuffle')
        btnCredits: $('.btn-credits')
        btnKeyboard: $('.btn-keyboard')
        btnShare: $('.btn-spread')
        dynamic: $('.dynamic-c')
        btn: $('.btn')
        lock: $('.lock')

    initUI: ->
      isQueued = 0

      @$el.sliderSize.dragslider
        value: @size
        rangeDrag: false
        min: 10
        max: 100
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
        value: 140 - @speed
        rangeDrag: false
        min: 30
        max: 110
        step: 10
        slide: (e, ui) =>
          # update speed while sliding
          @speed = 140 - ui.value
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

      # show UI
      unless @interface is 0
        @$el.uiHolder.show()

      # lock state
      @updateLockStates()
      @$el.lock.click @toggleLock

      # button hover behavior
      @$el.btn.hover ->
        $(this).addClass("dynamic-c").css color: "hsl(#{@accent}, 80%, 70%)"
        true
      , ->
        $this = $(this)
        # get button's corresponding ui box class
        el = $this.attr("class").split(" ")[1].split("-")[1]
        # remove hover highlight except if box open
        unless $("." + el).is(":visible")
          # keep highlighted while box open
          $this.removeClass "dynamic-c"
          $this.css color: "rgb(200,200,200)"
        true


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
      @dataToUI()
      @changeUIColor()

    draw: (d) ->
      # d is 1 means no mirrored subdivisions, maximum randomness
      # w & h are num of sqaures to fill screen at this sqaure size and # of mirrored subdivisions
      d = d * @pattern
      s = @size
      w = Math.floor(@view.w / @size)
      h = Math.floor(@view.h / @size)
      w = Math.floor(w / d) + 1
      h = Math.floor(h / d) + 1

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
      @updateUI()
      @fillScreen()

    randomize: ->
      changed = false

      unless @locks.size
        @size = Math.round( @rand(10,100) / 10 ) * 10
        changed = true
      unless @locks.hue
        @hue = min: @rand(0,360), max: @rand(0,360)
        [@hue.min, @hue.max] = [@hue.max, @hue.min] if @hue.max < @hue.min
        changed = true
      unless @locks.sat
        @sat = min: @rand(40,80), max: @rand(60,100)
        [@sat.min, @sat.max] = [@sat.max, @sat.min] if @sat.max < @sat.min
        changed = true
      unless @locks.light
        @light = min: @rand(20,60), max: @rand(40,100)
        [@light.min, @light.max] = [@light.max, @light.min] if @light.max < @light.min
        changed = true
      # unless @locks.pattern
      #   @pattern = @rand(1,4)
      #   changed = true
      # unless @locks.speed
      #   @speed = @rand(20,100)
      #   changed = true
      
      changed

    deviceCheck: ->
      if navigator.userAgent.match(/iPhone/i)
        @$el.uiHolder.remove()
        true
      false

    toggleVisibility: (cl) ->
      $el = $('.'+cl)
      if $el.is(":visible")
        $el.hide()
      else
        $('.info').hide()
        $el.show()
      # remove accent color from currently highlighted button
      @$el.btn.removeClass('dynamic-c').css color: 'rgb(200,200,200)'
      $('.btn-'+cl).addClass('dynamic-c').css color: "hsl(#{@accent}, 80%, 70%)"

    toggleUI: ->
      $ui = @$el.uiHolder
      if $ui.is(':visible')
        @interface = 0
        $ui.hide()
      else
        @interface = 1
        $ui.show()
      @updateParams()

    changeUIColor: ->
      @accent = ( @hue.min + @hue.max ) / 2
      @$el.dynamic.css color: "hsl(#{@accent}, 80%, 70%)"

    genColor: (hue, sat, light) ->
      h = hue ? @rand( @hue.min, @hue.max )
      s = sat ? @rand( @sat.min, @sat.max )
      l = light ? @rand( @light.min, @light.max )
      "hsl(#{h},#{s}%,#{l}%)"

    updateParams: ->
      @dataToURL()
      @dataToUI()

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

    dataToURL: ->
      location.hash = @toParams()

    dataToUI: ->
      link = location.href
      @$el.uiData.html @toStr()
      @$el.shareLinkHref.attr 'href', link
      @$el.shareLinkTwitter.attr 'href', "http://twitter.com/home?status=I made this with %23glitchtop " + encodeURIComponent(link)

    updateUI: ->
      @$el.sliderSize.dragslider value: @size
      @$el.sliderHue.dragslider values: [@hue.min, @hue.max ]
      @$el.sliderSat.dragslider values: [ @sat.min, @sat.max ]
      @$el.sliderLight.dragslider values: [ @light.min, @light.max ]
      # @$el.sliderSpeed.dragslider value: @speed
      # @$el.sliderPattern.dragslider value: @pattern

    toParams: -> "#{@size}px&H=#{@hue.min}-#{@hue.max}&S=#{@sat.min}-#{@sat.max}&L=#{@light.min}-#{@light.max}&P=#{@pattern}&A=#{@animating}&I=#{@interface}"

    toStr: -> "#{@size}px, H=#{@hue.min}-#{@hue.max}, S=#{@sat.min}-#{@sat.max}, L=#{@light.min}-#{@light.max}"

    rand: (min, max) -> Math.floor( Math.random() * (max - min + 1) ) + min

  window.Glitchtop = new Glitchtop
