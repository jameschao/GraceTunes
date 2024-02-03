class API::SongsController < API::APIController
  SONGS_PER_PAGE_DEFAULT = 100

  def show
    @song = Song.find(params[:id])
    Song.increment_counter(:view_count, @song.id, touch: false)
    render json: @song
  end

  def index
    songs = Song

    # perform searching and filtering
    # pg_search requires search_by_keywords to be to run first before anything else
    songs = songs.search_by_keywords(params[:keywords]) if params[:keywords].present?
    songs = songs.where(key: params[:key]) if params[:key].present?
    songs = songs.where(tempo: params[:tempo]) if params[:tempo].present?
    songs = songs.select('id, artist, tempo, key, name, chord_sheet, spotify_uri')

    # reorder
    songs =
      case params[:sort]
      when 'Newest First'
        songs.reorder(created_at: :desc)
      when 'Most Popular First'
        songs.reorder(view_count: :desc)
      else
        # does nothing if search_by_keywords was run, in which case songs are already ordered by relevance
        songs.order(name: :asc)
      end

    # paginate
    if params[:start].present?
      page_size = (params[:length] || SONGS_PER_PAGE_DEFAULT).to_i
      page_num = (params[:start].to_i / page_size.to_i) + 1

      songs = songs.paginate(page: page_num, per_page: page_size)
    end

    render json: songs
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

  private

  def song_params
    params.require(:song)
          .permit(:name, :key, :artist, :tempo, :bpm, :standard_scan, :chord_sheet, :spotify_uri)
  end
end