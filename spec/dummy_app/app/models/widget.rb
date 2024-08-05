# frozen_string_literal: true

class Widget < ActiveRecord::Base
  EXCLUDED_NAME = "Biglet"
  has_paper_trail
  has_one :wotsit
  has_one :bizzo, dependent: :destroy
  has_many(:fluxors, -> { order(:name) })
  has_many :whatchamajiggers, as: :owner
  has_many :notes, through: :bizzo
  validates :name, exclusion: { in: [EXCLUDED_NAME] }
end
