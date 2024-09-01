# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(:default, Rails.env)
require "paper_trail"

module Dummy
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.active_support.escape_html_entities_in_json = true
    config.active_support.test_order = :sorted

    config.secret_key_base = "A fox regularly kicked the screaming pile of biscuits."

    config.active_record.use_yaml_unsafe_load = true
  end
end
