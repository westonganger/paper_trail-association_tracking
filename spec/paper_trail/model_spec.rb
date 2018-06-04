# frozen_string_literal: true

require "spec_helper"

RSpec.describe(::PaperTrail, versioning: true) do
  context "a new record" do
    it "not have any previous versions" do
      expect(Widget.new.versions).to(eq([]))
    end

    it "be live" do
      expect(Widget.new.paper_trail.live?).to(eq(true))
    end
  end

  context "a persisted record" do
    before do
      @widget = Widget.create(name: "Henry", created_at: (Time.now - 1.day))
    end

    it "have one previous version" do
      expect(@widget.versions.length).to(eq(1))
    end

    it "be nil in its previous version" do
      expect(@widget.versions.first.object).to(be_nil)
      expect(@widget.versions.first.reify).to(be_nil)
    end

    it "record the correct event" do
      expect(@widget.versions.first.event).to(match(/create/i))
    end

    it "be live" do
      expect(@widget.paper_trail.live?).to(eq(true))
    end

    it "use the widget `updated_at` as the version's `created_at`" do
      expect(@widget.versions.first.created_at.to_i).to(eq(@widget.updated_at.to_i))
    end

    describe "#changeset" do
      it "has expected values" do
        changeset = @widget.versions.last.changeset
        expect(changeset["name"]).to eq([nil, "Henry"])
        expect(changeset["id"]).to eq([nil, @widget.id])
        # When comparing timestamps, round off to the nearest second, because
        # mysql doesn't do fractional seconds.
        expect(changeset["created_at"][0]).to be_nil
        expect(changeset["created_at"][1].to_i).to eq(@widget.created_at.to_i)
        expect(changeset["updated_at"][0]).to be_nil
        expect(changeset["updated_at"][1].to_i).to eq(@widget.updated_at.to_i)
      end
    end

    context "and then updated without any changes" do
      before { @widget.touch }

      it "to have two previous versions" do
        expect(@widget.versions.length).to(eq(2))
      end
    end

    context "and then updated with changes" do
      before { @widget.update_attributes(name: "Harry") }

      it "have three previous versions" do
        expect(@widget.versions.length).to(eq(2))
      end

      it "be available in its previous version" do
        expect(@widget.name).to(eq("Harry"))
        expect(@widget.versions.last.object).not_to(be_nil)
        widget = @widget.versions.last.reify
        expect(widget.name).to(eq("Henry"))
        expect(@widget.name).to(eq("Harry"))
      end

      it "have the same ID in its previous version" do
        expect(@widget.versions.last.reify.id).to(eq(@widget.id))
      end

      it "record the correct event" do
        expect(@widget.versions.last.event).to(match(/update/i))
      end

      it "have versions that are not live" do
        @widget.versions.map(&:reify).compact.each do |v|
          expect(v.paper_trail).not_to be_live
        end
      end

      it "have stored changes" do
        last_obj_changes = @widget.versions.last.object_changes
        actual = PaperTrail.serializer.load(last_obj_changes).reject do |k, _v|
          (k.to_sym == :updated_at)
        end
        expect(actual).to(eq("name" => %w[Henry Harry]))
        actual = @widget.versions.last.changeset.reject { |k, _v| (k.to_sym == :updated_at) }
        expect(actual).to(eq("name" => %w[Henry Harry]))
      end

      it "return changes with indifferent access" do
        expect(@widget.versions.last.changeset[:name]).to(eq(%w[Henry Harry]))
        expect(@widget.versions.last.changeset["name"]).to(eq(%w[Henry Harry]))
      end

      context "and has one associated object" do
        before { @wotsit = @widget.create_wotsit name: "John" }

        it "not copy the has_one association by default when reifying" do
          reified_widget = @widget.versions.last.reify
          expect(reified_widget.wotsit).to(eq(@wotsit))
          expect(@widget.reload.wotsit).to(eq(@wotsit))
        end

        it "copy the has_one association when reifying with :has_one => true" do
          reified_widget = @widget.versions.last.reify(has_one: true)
          expect(reified_widget.wotsit).to(be_nil)
          expect(@widget.reload.wotsit).to(eq(@wotsit))
        end
      end

      context "and has many associated objects" do
        before do
          @f0 = @widget.fluxors.create(name: "f-zero")
          @f1 = @widget.fluxors.create(name: "f-one")
          @reified_widget = @widget.versions.last.reify
        end

        it "copy the has_many associations when reifying" do
          expect(@reified_widget.fluxors.length).to(eq(@widget.fluxors.length))
          expect(@reified_widget.fluxors).to match_array(@widget.fluxors)
          expect(@reified_widget.versions.length).to(eq(@widget.versions.length))
          expect(@reified_widget.versions).to match_array(@widget.versions)
        end
      end

      context "and has many associated polymorphic objects" do
        before do
          @f0 = @widget.whatchamajiggers.create(name: "f-zero")
          @f1 = @widget.whatchamajiggers.create(name: "f-zero")
          @reified_widget = @widget.versions.last.reify
        end

        it "copy the has_many associations when reifying" do
          expect(@reified_widget.whatchamajiggers.length).to eq(@widget.whatchamajiggers.length)
          expect(@reified_widget.whatchamajiggers).to match_array(@widget.whatchamajiggers)
          expect(@reified_widget.versions.length).to(eq(@widget.versions.length))
          expect(@reified_widget.versions).to match_array(@widget.versions)
        end
      end

      context "polymorphic objects by themselves" do
        before { @widget = Whatchamajigger.new(name: "f-zero") }

        it "not fail with a nil pointer on the polymorphic association" do
          @widget.save!
        end
      end

      context "and then destroyed" do
        before do
          @fluxor = @widget.fluxors.create(name: "flux")
          @widget.destroy
          @reified_widget = PaperTrail::Version.last.reify
        end

        it "record the correct event" do
          expect(PaperTrail::Version.last.event).to(match(/destroy/i))
        end

        it "have three previous versions" do
          expect(PaperTrail::Version.with_item_keys("Widget", @widget.id).length).to(eq(3))
        end

        describe "#attributes" do
          it "returns the expected attributes for the reified widget" do
            expect(@reified_widget.id).to(eq(@widget.id))
            expected = @widget.attributes
            actual = @reified_widget.attributes
            expect(expected["id"]).to eq(actual["id"])
            expect(expected["name"]).to eq(actual["name"])
            expect(expected["a_text"]).to eq(actual["a_text"])
            expect(expected["an_integer"]).to eq(actual["an_integer"])
            expect(expected["a_float"]).to eq(actual["a_float"])
            expect(expected["a_decimal"]).to eq(actual["a_decimal"])
            expect(expected["a_datetime"]).to eq(actual["a_datetime"])
            expect(expected["a_time"]).to eq(actual["a_time"])
            expect(expected["a_date"]).to eq(actual["a_date"])
            expect(expected["a_boolean"]).to eq(actual["a_boolean"])
            expect(expected["type"]).to eq(actual["type"])
            expect(expected["created_at"].to_i).to eq(actual["created_at"].to_i)
            expect(expected["updated_at"].to_i).to eq(actual["updated_at"].to_i)
          end
        end

        it "be re-creatable from its previous version" do
          expect(@reified_widget.save).to(be_truthy)
        end

        it "restore its associations on its previous version" do
          @reified_widget.save
          expect(@reified_widget.fluxors.length).to(eq(1))
        end

        it "have nil item for last version" do
          expect(@widget.versions.last.item).to(be_nil)
        end

        it "not have changes" do
          expect(@widget.versions.last.changeset).to(eq({}))
        end
      end
    end
  end

  context ":has_many :through" do
    before do
      @book = Book.create(title: "War and Peace")
      @dostoyevsky = Person.create(name: "Dostoyevsky")
      @solzhenitsyn = Person.create(name: "Solzhenitsyn")
    end

    it "store version on source <<" do
      count = PaperTrail::Version.count
      (@book.authors << @dostoyevsky)
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(@book.authorships.first.versions.first).to(eq(PaperTrail::Version.last))
    end

    it "store version on source create" do
      count = PaperTrail::Version.count
      @book.authors.create(name: "Tolstoy")
      expect((PaperTrail::Version.count - count)).to(eq(2))
      expect(
        [PaperTrail::Version.order(:id).to_a[-2].item, PaperTrail::Version.last.item]
      ).to match_array([Person.last, Authorship.last])
    end

    it "store version on join destroy" do
      (@book.authors << @dostoyevsky)
      count = PaperTrail::Version.count
      @book.authorships.reload.last.destroy
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(PaperTrail::Version.last.reify.book).to(eq(@book))
      expect(PaperTrail::Version.last.reify.author).to(eq(@dostoyevsky))
    end

    it "store version on join clear" do
      (@book.authors << @dostoyevsky)
      count = PaperTrail::Version.count
      @book.authorships.reload.destroy_all
      expect((PaperTrail::Version.count - count)).to(eq(1))
      expect(PaperTrail::Version.last.reify.book).to(eq(@book))
      expect(PaperTrail::Version.last.reify.author).to(eq(@dostoyevsky))
    end
  end
end
