# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  permits :username, :email, :password, model_name: "User"

  def new
    @user = User.new_with_session({}, session)
  end

  def create(user)
    @user = User.new(user).build_relations
    @user.time_zone = cookies["ann_time_zone"].presence || "Asia/Tokyo"
    @user.locale = locale

    return render(:new) unless @user.valid?

    ActiveRecord::Base.transaction do
      @user.save!
      ga_client.user = @user
      ga_client.events.create(:users, :create)
      keen_client.publish(
        "create_users",
        user: @user,
        via: "web",
        via_oauth: false
      )
    end

    bypass_sign_in(@user)

    flash[:notice] = t("messages.registrations.create.confirmation_mail_has_sent")
    redirect_to after_sign_in_path_for(@user)
  end
end
