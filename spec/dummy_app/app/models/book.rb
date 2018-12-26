# frozen_string_literal: true

class Book < ActiveRecord::Base
  has_many :authorships, dependent: :destroy
  has_many :authors, through: :authorships

  has_many :editorships, dependent: :destroy
  has_many :editors, through: :editorships

  has_many :notes, as: :object

  has_paper_trail
end
