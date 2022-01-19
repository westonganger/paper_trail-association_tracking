# frozen_string_literal: true

class Hunt < ActiveRecord::Base
  belongs_to :predator, class_name: "Animal"
  belongs_to :prey, class_name: "Animal"
  has_paper_trail
end