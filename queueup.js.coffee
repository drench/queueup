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

  playable: -> @audioTag.paused && @audioTag.src

  stop: ->
    @audioTag.pause()
    @audioTag.src = ""

  next: ->
    @playlist.goForward()
    @stop() if @playlist.currentSong.isNull()

  prev: ->
    @playlist.goBackward()
    @stop() if @playlist.currentSong.isNull()

  queueup: (song) -> @playlist.queueup(song)

  trashCurrentSong: ->
    @playlist.setCurrentSong()
    @next()

class window.QueueupControl
  constructor: (@player) -> @initializeEvents()

  initializeEvents: ->
    @initializeEmptyButton()
    @initializeNextButton()
    @initializePrevButton()
    @initializeAddFileButtons()
    @initializeDequeueButtons()
    @initializeShuffleButton()

  initializeShuffleButton: ->
    @$shuffleButton = jQuery(".shuffle")
    @$shuffleButton.on "click", () =>
      @shuffle = !@shuffle
      if @shuffle
        @player.playlist.shuffleUnplayed()
        @$shuffleButton.addClass("inset")
      else
        @$shuffleButton.removeClass("inset")

  initializeAddFileButtons: ->
    jQuery(".add-file").on "click", (event) =>
      event.preventDefault()
      $target = jQuery(event.target)
      @player.queueup(new Song($target.data("href"), $target.parents("tr")))


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

  new Vue
    el: "body"
    data:
      player: window.player
