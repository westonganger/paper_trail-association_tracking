# frozen_string_literal: true

# A version class that includes the concern instead of subclassing
# `PaperTrail::Version`, which paper_trail's version_concern.rb allows.
class ConcernOnlyVersion < ActiveRecord::Base
  include PaperTrail::VersionConcern
  self.table_name = "versions"
end
