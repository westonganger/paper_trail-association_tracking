# frozen_string_literal: true

require "spec_helper"

RSpec.describe Person, type: :model, versioning: true do
  it "baseline test setup" do
    expect(Person.new).to be_versioned
  end

  describe "#cars and bicycles" do
    it "can be reified" do
      person = Person.create(name: "Frank")
      car = Car.create(name: "BMW 325")
      bicycle = Bicycle.create(name: "BMX 1.0")

      person.car = car
      person.bicycle = bicycle
      person.update_attributes(name: "Steve")

      car.update_attributes(name: "BMW 330")
      bicycle.update_attributes(name: "BMX 2.0")
      person.update_attributes(name: "Peter")

      expect(person.reload.versions.length).to(eq(3))

      # See https://github.com/airblade/paper_trail/issues/594
      expect {
        person.reload.versions.second.reify(has_one: true)
      }.to(
        raise_error(::PaperTrailAssociationTracking::Reifiers::HasOne::FoundMoreThanOne) do |err|
          expect(err.message.squish).to match(
            /Expected to find one Vehicle, but found 2/
          )
        end
      )
    end
  end

  describe "#notes" do
    it "can be reified" do
      person = Person.create!(id: 1, name: "Jessica")
      book = Book.create!(id: 1, title: "La Chute")
      person_note = Note.create!(body: "Some note on person", object: person)
      book_note = Note.create!(body: "Some note on book", object: book)

      person.update_attributes!(name: "Jennyfer")
      book_note.update_attributes!(body: "Modified note on book")
      person_note.update_attributes!(body: "Modified note on person")

      reified_person = person.versions.last.reify(has_many: true)
      expect(reified_person.notes.length).to eq(1)
      expect(reified_person.notes.first.body).to eq("Some note on person")
    end
  end
end
