class API::Audits::SongsController < API::APIController
  DEFAULT_PAGE_SIZE = 20

  def show
    song = Song.find(params[:id])
    # only show 100 most recent audits to prevent DOS
    update_audits = song.audits.updates.limit(100)
    render json: update_audits
  end

  def index
    page_num = params[:page_num] ? params[:page_num].to_i : 1
    page_size = params[:page_size] ? params[:page_size].to_i : DEFAULT_PAGE_SIZE

    audits = Audited.audit_class.order(created_at: :desc)
    audits = audits.where(action: params[:action]) if AuditAction.valid_action?(params[:action])
    audits = audits.paginate(page: page_num, per_page: page_size)

    audits_info_list = audits.map do |audit|
      song = Song.find_by(id: audit.auditable_id)
      if song.nil?
        is_deleted = true
        song_name = SongDeletionRecord.find(audit.auditable_id).name
      else
        is_deleted = false
        song_name = song.name
      end
      [audit, song_name, is_deleted]

    end

    render json: audits_info_list
  end
end
