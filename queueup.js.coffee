class window.Song
  constructor: (@url = undefined, @$row = undefined) ->
  @null: new @
  isNull: -> !@url

  toS: ->
    if @isNull() || !@$row
      ""
    else
      "#{@artist()} - #{@title()}"

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

  shuffleUnplayed: ->
    shuffled = ArrayShuffler.shuffle(@unplayed)
    @unplayed = []
    @unplayed = shuffled

class ArrayShuffler
  @shuffle: (array) ->
    index = array.length
    while index > 1
      randomSlot = Math.floor(index * Math.random())
      index -= 1
      [array[index], array[randomSlot]] = [array[randomSlot], array[index]]
    array

class MediaTag
  constructor: (@element) ->
    @$ = jQuery(@element)

  formatTimeDisplay: ->
    if isFinite(@element.duration)
      TimeFormatter.mmss(@element.currentTime) +
      " of " +
      TimeFormatter.mmss(@element.duration)
    else
      ""

  pause: -> @element.pause()
  paused: -> @element.paused
  play: -> @element.play()
  playable: -> @element.paused && @element.src

  stop: ->
    @element.pause()
    @element.src = ""

class TimeFormatter
  @mmss: (seconds) ->
    minutes = Math.floor(seconds / 60.0)
    seconds = Math.floor(seconds - (minutes * 60))
    "#{@._pad(minutes)}:#{@._pad(seconds)}"

  @_pad: (integer) ->
    if integer > 9 then integer.toString() else "0#{integer}"

class window.Player
  constructor: (@mediaTag, @playlist = new Playlist) ->
    @mediaTag.$.on "ended", => @next()
    @initializeDurationEvent()

  initializeDurationEvent: ->
    @timeDisplay = ""
    @mediaTag.$.on "timeupdate", => @timeDisplay = @mediaTag.formatTimeDisplay()

  pause: -> @mediaTag.pause()
  paused: -> @mediaTag.paused()
  play: -> @mediaTag.play()
  playable: -> @mediaTag.playable()
  stop: -> @mediaTag.stop()

  next: ->
    @playlist.goForward()
    @stop() if @playlist.currentSong.isNull()

  on: (eventType, callback) -> @mediaTag.$.on(eventType, callback)

  prev: ->
    @playlist.goBackward()
    @stop() if @playlist.currentSong.isNull()

  queueup: (song) ->
    @playlist.queueup(song)
    @play() unless song.isNull()

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

    if @player.paused() then @showPlayControls() else @showPauseControls()

    @player
      .on("pause", => @showPlayControls())
      .on("playing", => @showPauseControls())

    @$pauseButton.on "click", => @player.pause()

    @$playButton.on "click", =>
      if @player.playable() then @player.play()

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
    jQuery(".add-multiple-files").on "click", =>
      jQuery("#library tbody tr").each (_, row) =>
        $row = jQuery(row)
        href = $row.find(".add-file i").data("href")
        @player.queueup(new Song(href, $row))

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
  window.mediaTag = new MediaTag(document.querySelector("audio"))
  window.player = new Player(mediaTag)
  window.queueupControl = new QueueupControl(player)

  window._vue = new Vue
    el: "body"
    data:
      player: window.player

  window._filter = new List("library", valueNames: ["album", "artist"])
