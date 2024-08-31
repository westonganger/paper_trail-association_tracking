source "https://rubygems.org"

gemspec

gem 'rails-controller-testing'

def get_env(name)
  (ENV[name] && !ENV[name].empty?) ? ENV[name] : nil
end

gem "rails", get_env("RAILS_VERSION")

db_gem = get_env("DB_GEM") || "sqlite3"
gem db_gem, get_env("DB_GEM_VERSION")

gem 'paper_trail', get_env("PAPER_TRAIL_VERSION")
