# frozen_string_literal: true

require "spec_helper"

RSpec.describe WidgetsController, type: :controller, versioning: true do
  before do
  end

  after do
    RequestStore.store[:paper_trail] = nil
  end

  describe "#create" do
    context "PT enabled" do
      #it "stores information like IP address in version" do
      #  post(:create, params_wrapper(widget: { name: "Flugel" }))
      #  widget = assigns(:widget)
      #  expect(widget.versions.length).to(eq(1))
      #  expect(widget.versions.last.whodunnit.to_i).to(eq(153))
      #  expect(widget.versions.last.ip).to(eq("127.0.0.1"))
      #  expect(widget.versions.last.user_agent).to(eq("Rails Testing"))
      #end
    end
  end
end
