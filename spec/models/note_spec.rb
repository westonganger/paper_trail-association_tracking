# frozen_string_literal: true

require "spec_helper"

RSpec.describe Note, type: :model, versioning: true do
  it "baseline test setup" do
    expect(Note.new).to be_versioned
  end

  describe "#object" do
    it "can be reified" do
      person = Person.create!(name: "Marielle")
      note = Note.create!(body: "Note on Marielle", object: person)

      note.update!(body: "Modified note")
      person.update!(name: "Modified")

      reified_note = note.versions.last.reify(belongs_to: true)
      expect(reified_note.body).to eq("Note on Marielle")
      expect(reified_note.object.name).to eq("Marielle")
    end
  end
end
