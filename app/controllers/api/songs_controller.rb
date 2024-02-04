class API::SongsController < API::APIController
  SONGS_PER_PAGE_DEFAULT = 100

  def show
    @song = Song.find_by(id: params[:id])
    if @song
      case params[:format]
      when 'numbers'
        Formatter.format_song_nashville(@song)
      when 'no_chords'
        Formatter.format_song_no_chords(@song)
      else
        Transposer.transpose_song(@song, params[:key]) if params[:key].present?
      end

      Song.increment_counter(:view_count, @song.id, touch: false)
      render json: @song
    else
      render json: API::APIError.new("Song not found")
    end
  end

  # Query params are single letter to save space, since HTTP urls
  def index
    songs = Song

    # perform searching and filtering
    # pg_search requires search_by_keywords to be to run first before anything else
    songs = songs.search_by_keywords(params[:query]) if params[:query].present?
    songs = songs.where(key: params[:key]) if params[:key].present?
    songs = songs.where(tempo: params[:tempo]) if params[:tempo].present?
    songs = songs.select('id, artist, tempo, key, name, chord_sheet, spotify_uri')
    matching_songs_count = songs.length

    # reorder
    songs =
      case params[:sort_by]
      when 'created_at'
        songs.reorder(created_at: :desc)
      when 'views'
        songs.reorder(view_count: :desc)
      else
        # does nothing if search_by_keywords was run, in which case songs are already ordered by relevance
        songs.order(name: :asc)
      end

    # paginate
    page_num = params[:page_num]&.to_i || 1
    page_size = [params[:page_size]&.to_i || SONGS_PER_PAGE_DEFAULT, 500].min

    songs = songs.paginate(page: page_num, per_page: page_size)

    render json: API::PaginatedResult.new(songs, matching_songs_count, Song.count)
  end

  def create
    @song = Song.new(song_params)
    if @song.save
      flash[:success] = "#{@song.name} successfully created!"
      render json: @song
    else
      render json: API::APIError.new("Couldn't save song", @song.errors), status: :bad_request
    end
  end

  def update
    @song = Song.find(params[:id])
    if @song.update(song_params)
      render json: @song
    else
      render json: API::APIError.new("Couldn't edit song", @song.errors), status: :bad_request
    end
  end

  def destroy
    @song = Song.find_by(id: params[:id])
    if @song.nil?
      render json: API::APIError.new("No song with id #{params[:id]}")
    elsif @song.destroy
      head :no_content
    else
      logger.info "#{current_user} tried to delete #{@song} but failed"
      render json: API::APIError.new("Unable to delete song #{params[:id]}"), status: :internal_server_error
    end
  end

  private

  def song_params
    params.require(:song)
          .permit(:name, :key, :artist, :tempo, :bpm, :standard_scan, :chord_sheet, :spotify_uri)
  end
end