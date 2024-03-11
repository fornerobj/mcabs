# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :authenticate_user!  # Ensures the user is signed in
  before_action :check_admin         # Custom filter to check for admin status
  layout 'authenticated_layout'

  def index
    @users = User.all
    @users = User.all.order(is_admin: :desc, full_name: :asc)
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where('full_name LIKE ? OR email LIKE ?', search_term, search_term)
    end
    
  end

  def promote_to_admin
    user = User.find(params[:id])
    user.update!(is_admin: true)
    redirect_to admin_index_path, notice: "#{user.email} has been promoted to admin."
  end

  def demote_to_user
    user = User.find(params[:id])
    user.update!(is_admin: false)
    redirect_to admin_index_path, notice: "#{user.email} has been demoted to user."
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_index_path, notice: "#{user.email} was successfully updated."
    else
      render :index, status: :unprocessable_entity
    end
  end

  def delete
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to admin_index_path, notice: "#{user.email} was successfully removed."
  end

  def upcoming_events
    @events = Event.where('"eventTime" > ?', Time.now)
  end

  def event
    @event = Event.find(params[:id])
    @rsvps = @event.rsvps
    @rsvp_count = @rsvps.count
  end

  def demographics
    @users = User.all
    apply_filters

    # prepare data for charts or tables here
    @gender_distribution = User.group(:gender).count
    @ethnicity_distribution = User.group(:is_hispanic_or_latino).count
    @race_distribution = User.group(:race).count
    @us_citizen_distribution = User.group(:is_us_citizen).count
    @first_generation_college_student_distribution = User.group(:is_first_generation_college_student).count
    @classification_distribution = User.group(:classification).count

    respond_to do |format|
      format.html # For the webpage
      format.json { render json: @users} 
      format.csv { send_data @users.to_csv, filename: "demographics-#{Date.today}.csv" }
    end

  end

  def export_demographics
    send_data User.to_csv, filename: "export-of-user-demographics-#{Date.today}.csv"
  end

  private

  def check_admin
    return if current_user&.admin?

    flash[:alert] = 'You are not authorized to access this page.'
    redirect_to root_path # or any other path you wish to redirect to
  end

  def apply_filters
  #   @users = User.all
  # @users = @users.by_gender(params[:gender]) if params[:gender].present?
  # @users = @users.by_race(params[:race]) if params[:race].present?
  # @users = @users.by_us_citizen(params[:is_us_citizen]) if params[:is_us_citizen].present?
  # @users = @users.by_first_generation_college_student(params[:is_first_generation_college_student]) if params[:is_first_generation_college_student].present?
  # @users = @users.by_hispanic_or_latino(params[:is_hispanic_or_latino]) if params[:is_hispanic_or_latino].present?
  # @users = @users.by_classification(params[:classification]) if params[:classification].present?
    @users = @users.by_gender(params[:gender])
                   .by_race(params[:race])
                   .by_us_citizen(params[:is_us_citizen])
                   .by_first_generation_college_student(params[:is_first_generation_college_student])
                   .by_hispanic_or_latino(params[:is_hispanic_or_latino])
                   .by_classification(params[:classification])
    # Extend with additional filters as needed
  end

end
