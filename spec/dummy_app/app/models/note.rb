class Note < ActiveRecord::Base
  belongs_to :object, polymorphic: true
  has_paper_trail
end
