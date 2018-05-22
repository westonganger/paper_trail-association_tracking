# frozen_string_literal: true

require "rspec/core"
require "rspec/matchers"
require "paper_trail/frameworks/rspec/helpers"

RSpec::Matchers.define :have_a_version_with do |attributes|
  # check if the model has a version with the specified attributes
  match do |actual|
    versions_association = actual.class.versions_association_name
    actual.send(versions_association).where_object(attributes).any?
  end
end

RSpec::Matchers.define :have_a_version_with_changes do |attributes|
  # check if the model has a version changes with the specified attributes
  match do |actual|
    versions_association = actual.class.versions_association_name
    actual.send(versions_association).where_object_changes(attributes).any?
  end
end
