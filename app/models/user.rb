class User < ActiveRecord::Base

  belongs_to :client
  belongs_to :subgroup

  def authenticate(val)
    self.encrypted_password == val
  end

  def is_owner?
    self.role_type == "owner"
  end

  def is_admin?
    self.role_type == "admin"
  end

  def is_spoc?
    self.role_type == "spoc"
  end

  def is_approver?
    self.role_type == "approver"
  end

  def is_vendor?
    self.role_type == "vendor"
  end

  def is_admin_or_owner?
    is_admin? or is_owner?
  end

  def operators
    Operator.where(:vendor_id => id)
  end

  def email_body
      body = "<html> User #{self.name} :"
      body += "<a href='http://generator.innovatiview.com'>http://generator.innovatiview.com</a>"
      body += "<br> Email - #{self.email}"
      body += "<br> Password - #{self.encrypted_password}"
      body += "</html>"
   end

  def notify
    begin
      RestClient.post "https://api:key-ad59eb535febe7c7ff00bc1b64bf2b25"\
        "@api.mailgun.net/v3/iv-genset.com/messages",
        :from => "Innovatiview <info@innovatiview.com>",
        :to => self.email,
        :subject => "Genset account created",
        :html => email_body
      Rails.logger.info "Emailed sent to user #{self.name} successfully"
    rescue => e
      Rails.logger.error "There was an error in sending email to #{self.email} for booking - #{self.name} due to #{e}"
    end
  end

end