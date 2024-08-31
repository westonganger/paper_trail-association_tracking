# PaperTrail-AssociationTracking

<a href="https://badge.fury.io/rb/paper_trail-association_tracking" target="_blank"><img height="21" style='border:0px;height:21px;' border='0' src="https://badge.fury.io/rb/paper_trail-association_tracking.svg" alt="Gem Version"></a>
<a href='https://github.com/westonganger/paper_trail-association_tracking/actions' target='_blank'><img src="https://github.com/westonganger/paper_trail-association_tracking/actions/workflows/test.yml/badge.svg?branch=master" style="max-width:100%;" height='21' style='border:0px;height:21px;' border='0' alt="CI Status"></a>
<a href='https://rubygems.org/gems/paper_trail-association_tracking' target='_blank'><img height='21' style='border:0px;height:21px;' src='https://img.shields.io/gem/dt/paper_trail-association_tracking?color=brightgreen&label=Rubygems%20Downloads' border='0' alt='RubyGems Downloads' /></a>

Plugin for the [PaperTrail](https://github.com/paper-trail-gem/paper_trail.git) gem to track and reify associations. This gem was extracted from PaperTrail for v9.2.0 to simplify things in PaperTrail and association tracking separately.

**PR's will happily be accepted**

PaperTrail-AssociationTracking can restore three types of associations: Has-One, Has-Many, and Has-Many-Through.

It will store in the `version_associations` table additional information to correlate versions of the association and versions of the model when the associated record is changed. When reifying the model, it will utilize this table, together with the `transaction_id` to find the correct version of the association and reify it. The `transaction_id` is a unique id for version records created in the same transaction. It is used to associate the version of the model and the version of the association that are created in the same transaction.

## Table of Contents

- [Alternative Solution](#alternative-solution)
- [Install](#install)
- [Usage](#usage)
- [Limitations](#limitations)
- [Known Issues](#known-issues)
- [Contributing](#contributing)
- [Credits](#credits)

# Alternative Solution

Model versioning and restoration require concious thought, design, and understanding. You should understand your versioning and restoration process completely. This gem paper_trail-association-tracking is mostly a blackbox solution which encourages you to set it up and then assume its Just Working<sup>TM</sup>. This can make for major data problems later.

Instead I recommend a newer gem that I have created for handling snapshots of records and associations called [active_snapshot](https://github.com/westonganger/active_snapshot). This gem does not utilize `paper_trail` at all. The focus of the [active_snapshot](https://github.com/westonganger/active_snapshot) gem is to have a simple and fully understandable design is easy to customize and know inside and out for your projects needs.

# Install

```ruby
gem 'paper_trail'
gem 'paper_trail-association_tracking'
```

Then run `rails generate paper_trail_association_tracking:install` which will do the following two things for you:

1. Create a `version_associations` table
2. Set `PaperTrail.config.track_associations = true` in an initializer

# Usage

First, ensure that you have added `has_paper_trail` to your main model and all associated models that are to be tracked.

To restore associations as they were at the time you must pass any of the following options to the `reify` method.

- To restore Has-Many and Has-Many-Through associations, use option `has_many: true`
- To restore Has-One associations , use option `has_one: true` to `reify`
- To restore Belongs-To associations, use option `belongs_to: true`

For example:

```ruby
item.versions.last.reify(has_many: true, has_one: true, belongs_to: false)
```

If you want the reified associations to be saved upon calling `save` on the parent model then you must set `autosave: true` on all required associations. A little tip, `accepts_nested_attributes` automatically sets `autosave` to true but you should probably still state it explicitly.

For example:

```ruby
class Product
  has_many :photos, autosave: true
end

product = Product.first.versions.last.reify(has_many: true, has_one: true, belongs_to: false)
product.save! ### now this will also save all reified photos
```

If you do not set `autosave: true` true on the association then you will have to save/delete them manually.

For example:

```ruby
class Product < ActiveRecord::Base
  has_paper_trail
  has_many :photos, autosave: false ### or if autosave not set
end

product = Product.create(name: 'product_0')
product.photos.create(name: 'photo')
product.update(name: 'product_a')
product.photos.create(name: 'photo')

reified_product = product.versions.last.reify(has_many: true, mark_for_destruction: true)
reified_product.save!
reified_product.name # product_a
reified_product.photos.size # 2
reified_product.photos.reload
reified_product.photos.size # 1 ### bad, didnt save the associations

product = Product.create(name: 'product_1')
product.update(name: 'product_b')
product.photos.create(name: 'photo')

reified_product = product.versions.last.reify(has_many: true, mark_for_destruction: true)
reified_product.save!
reified_product.name # product_b
reified_product.photos.size # 1
reified_product.photos.each{|x| x.marked_for_destruction? ? x.destroy! : x.save! }
reified_product.photos.size # 0
```

It will also respect AR transactions by utilizing the aforementioned `transaction_id` to reify the models as they were before the transaction (instead of before the update to the model).

For example:

```ruby
item.amount                  # 100
item.location.latitude       # 12.345

Item.transaction do
  item.location.update(latitude: 54.321)
  item.update(amount: 153)
end

t = item.versions.last.reify(has_one: true)
t.amount                         # 100
t.location.latitude              # 12.345, instead of 54.321
```

# Configuration

You can configure a different version association class by using the following configuration:

```ruby
class ProductionVersionAssociation < PaperTrail::VersionAssociation
  # You can change the table name, i.e.:
  self.table_name = "product_version_associations"
end

class Product < ActiveRecord::Base
  has_paper_trail version_associations: { class_name: "ProductVersionAssociation" }
end
```

# Limitations

1. Only reifies the first level of associations. If you want to include nested associations simply add `:through` relationships to your model.
1. Currently we only supports a single `version_associations` table. Therefore, you can only use a single table to store the versions for all related models.
1. Relies on the callbacks on the association model (and the `:through` association model for Has-Many-Through associations) to record the versions and the relationship between the versions. If the association is changed without invoking the callbacks, then reification won't work. Example:

    ```ruby
    class Book < ActiveRecord::Base
      has_many :authorships, dependent: :destroy
      has_many :authors, through: :authorships, source: :person
      has_paper_trail
    end

    class Authorship < ActiveRecord::Base
      belongs_to :book
      belongs_to :person
      has_paper_trail      # NOTE
    end

    class Person < ActiveRecord::Base
      has_many :authorships, dependent: :destroy
      has_many :books, through: :authorships
      has_paper_trail
    end

    ### Each of the following will store authorship versions:
    @book.authors << @john
    @book.authors.create(name: 'Jack')
    @book.authorships.last.destroy
    @book.authorships.clear
    @book.author_ids = [@john.id, @joe.id]

    ### But none of these will:
    @book.authors.delete @john
    @book.author_ids = []
    @book.authors = []
    ```


# Known Issues

1. Sometimes the has_one association will find more than one possible candidate and will raise a `PaperTrailAssociationTracking::Reifiers::HasOne::FoundMoreThanOne` error. For example, see `spec/models/person_spec.rb`
    - If you are not using STI, you may want to just assume the first result of multiple is the correct one and continue. PaperTrail <= v8 did this without error or warning. To do so add the following line to your initializer: `PaperTrail.config.association_reify_error_behaviour = :warn`. Valid options are: `[:error, :warn, :ignore]`
    - When using STI, even if you enable `:warn` you will likely still end up recieving an `ActiveRecord::AssociationTypeMismatch` error. See [PT Issue #594](https://github.com/airblade/paper_trail/issues/594). I strongly recommend that you do not use STI, however if you do need to decide to use STI, please see https://github.com/paper-trail-gem/paper_trail#4b1-the-optional-item_subtype-column
1. Not compatible with transactional tests, see [PT Issue #542](https://github.com/airblade/paper_trail/issues/542). However, apparently there has been some success by using the [transactional_capybara](https://rubygems.org/gems/transactional_capybara) gem.


# Contributing

We use the `appraisal` gem for testing multiple versions of `paper_trail` and `activerecord`. Please use the following steps to test using `appraisal`.

1. `bundle exec appraisal install`
2. `bundle exec appraisal rake test`


# Credits

Maintained by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)

Plugin authored by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)

Associations code originally contributed by Ben Atkins, Jared Beck, Andy Stewart & more
