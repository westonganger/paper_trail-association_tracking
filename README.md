# [WIP] paper_trail-association_tracking

[![Build Status][1]][2]

Plugin for the PaperTrail gem to track and reify associations

## TODO

- Verify patches in RecordTrail for `record_*` methods, would prefer an approach that utilizes super
- Verify patch of `Reifier#reify`, would prefer an approach that utilizes super
- Verify patch of `ModelConfig#setup` still works correctly given method ordering differences (Diff: https://github.com/paper-trail-gem/paper_trail/compare/master...remove_association_tracking)
- Continue removing most-non association specs
- Suppress deprecations in specs output
- Improve Readme
- Add consolidated list of paper trail plugins to paper_trail core readme

## Table of Contents

<!-- toc -->

- [1. Install](#1-install)
- [2. Associations](#2-associations)
- [3. Known Issues](#3-known-issues)
- [Articles](#articles)
- [Contributing](#contributing)
- [Credits](#credits)

<!-- tocstop -->

### 1. Install

1. Add to your `Gemfile`.

```ruby
gem 'paper_trail' # Requires v10+
gem 'paper_trail-association_tracking'
```

### 2. Association Tracking

This plugin currently can restore three types of associations: Has-One, Has-Many, and
Has-Many-Through. In order to do this, you will need to do two things:

1. Create a `version_associations` table
2. Set `PaperTrail.config.track_associations = true` (e.g. in an initializer)

Both will be done for you automatically if you install PaperTrail with the
`--with_associations` option
(e.g. `rails generate paper_trail:install --with-associations`)

If you want to add this functionality after the initial installation, you will
need to create the `version_associations` table manually, and you will need to
ensure that `PaperTrail.config.track_associations = true` is set.

PaperTrail will store in the `version_associations` table additional information
to correlate versions of the association and versions of the model when the
associated record is changed. When reifying the model, PaperTrail can use this
table, together with the `transaction_id` to find the correct version of the
association and reify it. The `transaction_id` is a unique id for version records
created in the same transaction. It is used to associate the version of the model
and the version of the association that are created in the same transaction.

To restore Has-One associations as they were at the time, pass option `has_one:
true` to `reify`. To restore Has-Many and Has-Many-Through associations, use
option `has_many: true`. To restore Belongs-To association, use
option `belongs_to: true`. For example:

```ruby
class Location < ActiveRecord::Base
  belongs_to :treasure
  has_paper_trail
end

class Treasure < ActiveRecord::Base
  has_one :location
  has_paper_trail
end

treasure.amount                  # 100
treasure.location.latitude       # 12.345

treasure.update_attributes amount: 153
treasure.location.update_attributes latitude: 54.321

t = treasure.versions.last.reify(has_one: true)
t.amount                         # 100
t.location.latitude              # 12.345
```

If the parent and child are updated in one go, PaperTrail can use the
aforementioned `transaction_id` to reify the models as they were before the
transaction (instead of before the update to the model).

```ruby
treasure.amount                  # 100
treasure.location.latitude       # 12.345

Treasure.transaction do
treasure.location.update_attributes latitude: 54.321
treasure.update_attributes amount: 153
end

t = treasure.versions.last.reify(has_one: true)
t.amount                         # 100
t.location.latitude              # 12.345, instead of 54.321
```

By default, PaperTrail excludes an associated record from the reified parent
model if the associated record exists in the live model but did not exist as at
the time the version was created. This is usually what you want if you just want
to look at the reified version. But if you want to persist it, it would be
better to pass in option `mark_for_destruction: true` so that the associated
record is included and marked for destruction. Note that `mark_for_destruction`
only has [an effect on associations marked with `autosave: true`](http://api.rubyonrails.org/classes/ActiveRecord/AutosaveAssociation.html#method-i-mark_for_destruction).

```ruby
class Widget < ActiveRecord::Base
  has_paper_trail
  has_one :wotsit, autosave: true
end

class Wotsit < ActiveRecord::Base
  has_paper_trail
  belongs_to :widget
end

widget = Widget.create(name: 'widget_0')
widget.update_attributes(name: 'widget_1')
widget.create_wotsit(name: 'wotsit')

widget_0 = widget.versions.last.reify(has_one: true)
widget_0.wotsit                                  # nil

widget_0 = widget.versions.last.reify(has_one: true, mark_for_destruction: true)
widget_0.wotsit.marked_for_destruction?          # true
widget_0.save!
widget.reload.wotsit                             # nil
```

#### 3. Known Issues

Associations are an **experimental feature** and have the following known
issues, in order of descending importance. Use in Production at your own risk.

1. PaperTrail only reifies the first level of associations.
1. Sometimes the has_one association will find more than one possible candidate and will raise a `PaperTrail::Reifiers::HasOne::FoundMoreThanOne` error. For example, see `spec/models/person_spec.rb`
  - If you are not using STI, you may want to just assume the first result (of multiple) is the correct one and continue. Versions pre v8.1.2 and below did this without error or warning. To do so add the following line to your initializer: `PaperTrail.config.association_reify_error_behaviour = :warn`. Valid options are: `[:error, :warn, :ignore]`
  - When using STI, even if you enable `:warn` you will likely still end up recieving an `ActiveRecord::AssociationTypeMismatch` error.
1. [#542](https://github.com/airblade/paper_trail/issues/542) -
   Not compatible with [transactional tests](https://github.com/rails/rails/blob/591a0bb87fff7583e01156696fbbf929d48d3e54/activerecord/lib/active_record/fixtures.rb#L142), aka. transactional fixtures.
1. Requires database timestamp columns with fractional second precision.
   - Sqlite and postgres timestamps have fractional second precision by default.
   [MySQL timestamps do not](https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html). Furthermore, MySQL 5.5 and earlier do not
   support fractional second precision at all.
   - Also, support for fractional seconds in MySQL was not added to
   rails until ActiveRecord 4.2 (https://github.com/rails/rails/pull/14359).
1. PaperTrail can't restore an association properly if the association record
   can be updated to replace its parent model (by replacing the foreign key)
1. Currently PaperTrail only supports a single `version_associations` table.
   Therefore, you can only use a single table to store the versions for
   all related models. Sorry for those who use multiple version tables.
1. PaperTrail relies on the callbacks on the association model (and the :through
   association model for Has-Many-Through associations) to record the versions
   and the relationship between the versions. If the association is changed
   without invoking the callbacks, Reification won't work. Below are some
   examples:

Given these models:

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
```

Then each of the following will store authorship versions:

```ruby
@book.authors << @dostoyevsky
@book.authors.create name: 'Tolstoy'
@book.authorships.last.destroy
@book.authorships.clear
@book.author_ids = [@solzhenistyn.id, @dostoyevsky.id]
```

But none of these will:

```ruby
@book.authors.delete @tolstoy
@book.author_ids = []
@book.authors = []
```

Having said that, you can apparently get all these working (I haven't tested it
myself) with this patch:

```ruby
# In config/initializers/active_record_patch.rb
module ActiveRecord
  # = Active Record Has Many Through Association
  module Associations
    class HasManyThroughAssociation < HasManyAssociation #:nodoc:
      alias_method :original_delete_records, :delete_records

      def delete_records(records, method)
        method ||= :destroy
        original_delete_records(records, method)
      end
    end
  end
end
```

See [issue 113](https://github.com/paper-trail-gem/paper_trail/issues/113) for a discussion about this.


### ActiveRecord Single Table Inheritance (STI)

At this time during `reify` any STI `has_one` associations will raise a `PaperTrail::Reifiers::HasOne::FoundMoreThanOne` error. See https://github.com/airblade/paper_trail/issues/594

Something to note though, is while the PaperTrail gem supports [Single Table Inheritance](http://api.rubyonrails.org/classes/ActiveRecord/Base.html#class-ActiveRecord::Base-label-Single+table+inheritance), I dont recommend STI ever. Your better off rolling your own solution rather than using STI.


## Articles

* [Example Title](the_article_url),
  [Example Author](the_author_url), 2018-05-18

## Contributing

See our [contribution guidelines](https://github.com/paper-trail-gem/paper_trail/blob/master/.github/CONTRIBUTING.md)

## Credits

Maintained by [Weston Ganger](https://github.com/westonganger)

Associations code originally authored by Ben Atkins, Jared Beck, & more

[1]: https://api.travis-ci.org/westonganger/paper_trail-association_tracking.svg?branch=master
[2]: https://travis-ci.org/westonganger/paper_trail-association_tracking
