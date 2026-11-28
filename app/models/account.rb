class Account < ApplicationRecord
  include Joinable

  HelpContact = Data.define(:name, :email_address)

  has_one_attached :logo do |attachable|
    attachable.variant :large, resize_to_limit: [ 512, 512 ], format: :png
    attachable.variant :small, resize_to_limit: [ 192, 192 ], format: :png
  end

  has_json :settings,
    restrict_room_creation_to_administrators: false,
    restrict_invite_to_administrators: false,
    help_contact_name:    :string,
    help_contact_email:   :string,
    code_of_conduct_url:  :string,
    minimum_age:          :integer

  validate :code_of_conduct_url_must_be_http_or_https

  def logo_variant(size)
    logo.variant(size).processed if logo.variable?
  end

  def help_contact
    fallback = User.administrator.first

    HelpContact.new(
      settings.help_contact_name.presence  || fallback&.name,
      settings.help_contact_email.presence || fallback&.email_address
    )
  end

  private
    def code_of_conduct_url_must_be_http_or_https
      url = settings.code_of_conduct_url.to_s.strip
      return if url.blank?

      uri = URI.parse(url)
      unless %w[ http https ].include?(uri.scheme)
        errors.add(:base, "Code of conduct URL must start with http:// or https://")
      end
    rescue URI::InvalidURIError
      errors.add(:base, "Code of conduct URL is not a valid URL")
    end
end
