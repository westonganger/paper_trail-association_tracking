# frozen_string_literal: true

class Animal < ActiveRecord::Base
  has_paper_trail
  self.inheritance_column = "species"
  has_many :prey, foreign_key: :predator_id, class_name: "Hunt"
end
