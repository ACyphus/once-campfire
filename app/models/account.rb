class Account < ApplicationRecord
  include Joinable

  HelpContact = Data.define(:name, :email_address)

  has_one_attached :logo
  has_json :settings,
    restrict_room_creation_to_administrators: false,
    restrict_invite_to_administrators: false,
    help_contact_name:  :string,
    help_contact_email: :string

  def help_contact
    fallback = User.administrator.first

    HelpContact.new(
      settings.help_contact_name.presence  || fallback&.name,
      settings.help_contact_email.presence || fallback&.email_address
    )
  end
end
