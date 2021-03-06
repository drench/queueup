require "cgi"
require "fileutils"
require "taglib"
require "uri"

# TODO:
# * sort files in track order; will need id3v2

class Queueup
  class Track
    attr_reader :fullpath

    def initialize(fullpath)
      @fullpath = fullpath
    end

    def album
      @album ||=
        TagLib::FileRef.open(fullpath) { |fileref| fileref.tag.album }.to_s
    end

    def artist
      @artist ||=
        TagLib::FileRef.open(fullpath) { |fileref| fileref.tag.artist }.to_s
    end

    def filename
      File.basename(@fullpath)
    end

    def html
      href = URI.escape(@fullpath, "?+()[] ")
      %Q{<tr>\n} +
      %Q{  <td>} +
      %Q{    <a class="add-file" title="queue this song" href="#{href}">} +
      %Q{      <i title="queue this song" class="fa fa-plus-square" data-href="#{href}"></i>} +
      %Q{    </a>\n} +
      %Q{  </td>\n} +
      %Q{  <td class="artist">#{CGI.escapeHTML(artist)}</td>\n} +
      %Q{  <td>#{CGI.escapeHTML(title)}</td>\n} +
      %Q{  <td class="album">#{CGI.escapeHTML(album)}</td>\n} +
      %Q{  <td>#{CGI.escapeHTML(track.to_s)}</td>\n} +
      %Q{  <td>#{CGI.escapeHTML(year.to_s)}</td>\n} +
      %Q{</tr>\n}
    end

    def title
      @title ||=
        TagLib::FileRef.open(fullpath) { |fileref| fileref.tag.title }.to_s
    end

    def track
      @track ||=
        TagLib::FileRef.open(fullpath) { |fileref| fileref.tag.track }.to_s
    end

    def year
      @year ||=
        TagLib::FileRef.open(fullpath) { |fileref| fileref.tag.year }.to_s
    end
  end

  def initialize(directory)
    @directory = directory
  end

  def html
    <<HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>queueup</title>
    <script src="http://code.jquery.com/jquery-2.2.1.min.js"></script>
    <link rel="stylesheet" href="HTML-KickStart-master/css/kickstart.css" />
    <script src="http://cdnjs.cloudflare.com/ajax/libs/coffee-script/1.1.2/coffee-script.min.js"></script>
    <script src="vue.js"></script>
    <script type="text/coffeescript" src="queueup.js.coffee"></script>
    <style>
      body {
        font-family: sans-serif;
        font-size: x-large;
      }

      #player button { margin-bottom: 20px }
      .library, .playlist {
        max-height: 200px;
        overflow-y: scroll;
      }
      audio { width: 127px }

      .library th, td {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        max-width: 100px;
      }
      .library th {
        resize: horizontal;
      }
    </style>
  </head>
  <body>
    <div class="grid flex">
      <div id="player">
        <button class="small prev fa fa-backward" v-bind:class="{ blue: player.playlist.anyPlayed() }" title="previous">
        </button>
        <button class="small pause fa fa-pause"></button>
        <button class="small play fa fa-play"></button>
        <audio autoplay="true" v-bind:src="player.playlist.currentSong.url"></audio>
        <button class="small next fa fa-forward" v-bind:class="{ blue: player.playlist.anyUnplayed() }" title="next">
        </button>
        <button v-bind:class="{ red: player.playlist.anyUnplayed() }" class="fa fa-ban small empty" title="clear queue">
        </button>
        <button class="shuffle fa fa-random small" v-bind:class="{ inset: player.playlist.shuffle }" title="shuffle mode">
        </button>
        <span class="elapsed-time">{{ player.timeDisplay }}</span>

        <table class="striped tight">
          <tr v-if="!player.playlist.currentSong.isNull()">
            <td>
              <a href="javascript://" class="dequeue" title="dequeue">
                <i class="fa fa-minus-circle" data-index="playing"></i>
              </a>
            </td>
            <td>{{ player.playlist.currentSong.toS() }}</td>
          </tr>
          <tr v-for="song in player.playlist.unplayed">
            <td>
              <a href="javascript://" class="dequeue" title="dequeue">
                <i class="fa fa-minus-circle" v-bind:data-index="$index"></i>
              </a>
            </td>
            <td>{{ song.toS() }}</td>
          </tr>
        </table>
      </div>

      <div id="library">
        <input class="search" placeholder="Filter artist or album" />
        <table class="striped tight library">
          <thead>
            <tr>
              <th>
                <a class="add-multiple-files" title="queue all songs listed below" href="javascript://">
                  <i class="fa fa-plus-square"></i>
                </a>
              </th>
              <th>Artist</th>
              <th>Title</th>
              <th>Album</th>
              <th>Track</th>
              <th>Year</th>
            </tr>
          </thead>
          <tbody class="list">
            #{as_table}
          </tbody>
        </table>
      </div>
    </div>
    <script src="HTML-KickStart-master/js/kickstart.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/list.js/1.2.0/list.min.js"></script>
  </body>
</html>
HTML
  end

  def as_table
    # TK assumes chdir happened!
    Dir.glob("**/*.mp3").map { |file| Track.new(file).html }.join("\n")
  end

  def install!
    FileUtils.install("queueup.js.coffee", @directory)
    FileUtils.install("vue.js", @directory)
    Kernel.system("rsync", "-aP", "HTML-KickStart-master", @directory)
    Dir.chdir(@directory) do
      # TK unlink it first if it exists! Or write to tmp and install the new file
      File.open("index.html", "w") { |index_html| index_html.puts(html) }
    end
  end
end
