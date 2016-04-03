class window.Song
  constructor: (@url = undefined, @$row = undefined) ->
  @null: new @
  isNull: -> !@url

  toS: ->
    if @isNull() || !@$row
      ""
    else
      "#{@artist()} - #{@title()}"

  old_toS: -> if @url? then unescape(@url) else ""
  artist: -> @$row.find("td")[1].innerText if @$row?
  title: -> @$row.find("td")[2].innerText if @$row?
  album: -> @$row.find("td")[3].innerText if @$row?
  track: -> @$row.find("td")[4].innerText if @$row?
  year: -> @$row.find("td")[5].innerText if @$row?

class window.Playlist
  constructor: ->
    @unplayed = []
    @played = []
    @setCurrentSong()
    @shuffle = false

  anyPlayed: -> @played.length > 0

  anyUnplayed: -> @unplayed.length > 0

  emptyUnplayedQueue: -> @unplayed = []

  dequeue: (index) -> @unplayed.splice(index, 1)

  goBackward: -> @_shiftCurrentSong(@unplayed, @played)

  goForward: -> @_shiftCurrentSong(@played, @unplayed)

  setCurrentSong: (song = Song.null) -> @currentSong = song

  _shiftCurrentSong: (listA, listB) ->
    listA.unshift(@currentSong) unless @currentSong.isNull()
    @setCurrentSong(listB.shift())

  _pushRandomly: (array, item) ->
    array.splice(Math.floor(Math.random() * (array.length + 1)), 0, item)

  queueup: (song) ->
    switch
      when @currentSong.isNull() then @setCurrentSong(song)
      when @shuffle then @_pushRandomly(@unplayed, song)
      else @unplayed.push(song)

  shuffleArray: (array) ->
    index = array.length
    while index > 1
      randomSlot = Math.floor(index * Math.random())
      index -= 1
      [array[index], array[randomSlot]] = [array[randomSlot], array[index]]
    array

  shuffleUnplayed: ->
    shuffled = @shuffleArray(@unplayed)
    @unplayed = []
    @unplayed = shuffled

class window.Player
  constructor: (@audioTag, @playlist = new Playlist) ->
    @audioTag.addEventListener "ended", => @next()
    @initializeDurationEvent()

  initializeDurationEvent: ->
    @timeDisplay = ""
    jQuery(@audioTag).on "timeupdate", => @timeDisplay = @formatTimeDisplay()

  playable: -> @audioTag.paused && @audioTag.src

  stop: ->
    @audioTag.pause()
    @audioTag.src = ""

  next: ->
    @playlist.goForward()
    @stop() if @playlist.currentSong.isNull()

  paused: -> @audioTag.paused

  play: -> @audioTag.play()

  prev: ->
    @playlist.goBackward()
    @stop() if @playlist.currentSong.isNull()

  queueup: (song) ->
    @playlist.queueup(song)
    @play() unless song.isNull()

  formatTimeDisplay: ->
    if isFinite(@audioTag.duration)
      @_mmss(@audioTag.currentTime) + " of " + @_mmss(@audioTag.duration)
    else
      ""

  _mmss: (seconds) ->
    minutes = Math.floor(seconds / 60.0)
    seconds = Math.floor(seconds - (minutes * 60))
    "#{@_zeropad(minutes)}:#{@_zeropad(seconds)}"

  _zeropad: (integer) ->
    if integer > 9 then integer.toString() else "0#{integer}"

  trashCurrentSong: ->
    @playlist.setCurrentSong()
    @next()

class window.QueueupControl
  constructor: (@player) -> @initializeEvents()

  initializeEvents: ->
    @initializeEmptyButton()
    @initializeNextButton()
    @initializePlayPauseButtons()
    @initializePrevButton()
    @initializeAddFileButtons()
    @initializeDequeueButtons()
    @initializeShuffleButton()

  showPlayControls: ->
    @$pauseButton.hide()
    @$playButton.show()

  showPauseControls: ->
    @$pauseButton.show()
    @$playButton.hide()

  initializePlayPauseButtons: -> # TODO: refactor
    @$pauseButton = jQuery(".pause")
    @$playButton = jQuery(".play")

    if @player.paused @showPlayControls() else @showPauseControls()

    jQuery(@player.audioTag)
      .on("pause", => @showPlayControls())
      .on("playing", => @showPauseControls())

    @$pauseButton.on "click", => @player.audioTag.pause()

    @$playButton.on "click", =>
      if @player.playable() then @player.audioTag.play()

  initializeShuffleButton: ->
    @$shuffleButton = jQuery(".shuffle")
    @$shuffleButton.on "click", () =>
      @shuffle = !@shuffle
      if @shuffle
        @player.playlist.shuffleUnplayed()
        @$shuffleButton.addClass("inset")
      else
        @$shuffleButton.removeClass("inset")

  queueupSongFromElement: ($element) ->
    href = $element.data("href")
    $row = $element.parents("tr")
    @player.queueup(new Song(href, $row))

  initializeAddFileButtons: ->
    jQuery(".add-file").on "click", (event) =>
      event.preventDefault()
      @queueupSongFromElement(jQuery(event.target))

  initializeDequeueButtons: ->
    jQuery("body").on "click", ".dequeue", (event) =>
      if event.target.dataset.index == "playing"
        @player.trashCurrentSong()
      else
        index = parseInt(event.target.dataset.index, 10)
        @player.playlist.dequeue(index)

  initializeNextButton: -> jQuery(".next").on "click", => @player.next()
  initializePrevButton: -> jQuery(".prev").on "click", => @player.prev()

  initializeEmptyButton: ->
    jQuery(".empty").on "click", => @player.playlist.emptyUnplayedQueue()

jQuery ->
  window.player = new Player(document.querySelector("audio"))
  window.queueupControl = new QueueupControl(player)

  window._vue = new Vue
    el: "body"
    data:
      player: window.player
