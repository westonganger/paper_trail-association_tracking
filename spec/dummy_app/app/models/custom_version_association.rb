# frozen_string_literal: true

class CustomVersionAssociation < PaperTrail::VersionAssociation
  belongs_to :version, class_name: "CustomVersion", foreign_key: :version_id, optional: true
end
