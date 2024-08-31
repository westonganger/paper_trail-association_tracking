# frozen_string_literal: true

class CustomVersion < PaperTrail::Version
  has_many :version_associations, class_name: "CustomVersionAssociation", foreign_key: :version_id, dependent: :destroy
end
