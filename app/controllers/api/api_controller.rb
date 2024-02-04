class API::APIController < ActionController::API

  before_action :require_sign_in

  DEFAULT_PAGE_SIZE = 100

  def require_sign_in
    head :forbidden if current_user.nil?
  end

  def require_edit_privileges
    head :forbidden unless current_user.can_edit?
  end

  def require_delete_privileges
    head :forbidden unless current_user.can_delete?
  end

  def current_user
    return @current_user if @current_user

    if [:user_email, :name, :role].all? { |field| session.key?(field) }
      @current_user = User.new(email: session[:user_email], name: session[:name], role: session[:role])
    end
  end

end