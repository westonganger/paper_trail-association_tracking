# frozen_string_literal: true

# Shares the bizzos table; its versions are not `PaperTrail::Version` records.
class AuditedBizzo < ActiveRecord::Base
  self.table_name = "bizzos"
  belongs_to :widget
  has_paper_trail versions: { class_name: "ConcernOnlyVersion" }
end
