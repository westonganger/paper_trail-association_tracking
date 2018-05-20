# [WIP] PaperTrail Associations Tracking

[![Build Status][4]][5] [![Dependency Status][6]][7]

paper_trail plugin to track and reify associations

## TODO

- Follow https://github.com/ankit1910/paper_trail-globalid for a Preffered method of implementation for the plugins patching
- Continue removing most-non association specs
- Decide what to do about transaction_id, It may be nice to leave this in paper_trail itself. Verify no statements regarding `transaction_id` were accidentally lost via initial cleanup commit
- Improve Readme
- Add consolidated list of paper trail plugins to offical paper_trail readme


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
gem 'paper_trail_associations_tracking'
```

### 2. Associations Tracking

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
only has [an effect on associations marked with `autosave: true`][32].

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
1. Does not fully support STI (For example, see `spec/models/person_spec.rb` and
   `PaperTrail::Reifiers::HasOne::FoundMoreThanOne` error)
1. [#542](https://github.com/airblade/paper_trail/issues/542) -
   Not compatible with [transactional tests][34], aka. transactional fixtures.
1. Requires database timestamp columns with fractional second precision.
   - Sqlite and postgres timestamps have fractional second precision by default.
   [MySQL timestamps do not][35]. Furthermore, MySQL 5.5 and earlier do not
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

See [issue 113][16] for a discussion about this.


### ActiveRecord Single Table Inheritance (STI)

At this time during `reify` any STI `has_one` associations will raise a `PaperTrail::Reifiers::HasOne::FoundMoreThanOne` error. See https://github.com/airblade/paper_trail/issues/594 

Something to note though, is while the offical PaperTrail gem supports [Single Table Inheritance][39], I dont recommend STI ever. Your better off rolling your own solution rather than using STI. 


## Articles

* [Example Title](the_article_url),
  [Example Author](the_author_url), 2018-05-18

## Contributing

See our [contribution guidelines][43]

## Credits

Maintained by [Weston Ganger](https://github.com/westonganger)

Associations code originally authored by Ben Atkins, Jared Beck, & more

[1]: http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html
[2]: https://github.com/paper-trail-gem/paper_trail/issues/163
[3]: http://railscasts.com/episodes/255-undo-with-paper-trail
[4]: https://api.travis-ci.org/paper-trail-gem/paper_trail.svg?branch=master
[5]: https://travis-ci.org/paper-trail-gem/paper_trail
[9]: https://github.com/paper-trail-gem/paper_trail/tree/3.0-stable
[10]: https://github.com/paper-trail-gem/paper_trail/tree/2.7-stable
[11]: https://github.com/paper-trail-gem/paper_trail/tree/rails2
[14]: https://raw.github.com/paper-trail-gem/paper_trail/master/lib/generators/paper_trail/templates/create_versions.rb
[16]: https://github.com/paper-trail-gem/paper_trail/issues/113
[17]: https://github.com/rails/protected_attributes
[18]: https://github.com/rails/strong_parameters
[19]: http://github.com/myobie/htmldiff
[20]: http://github.com/pvande/differ
[21]: https://github.com/halostatue/diff-lcs
[22]: http://github.com/jeremyw/paper_trail/blob/master/lib/paper_trail/has_paper_trail.rb#L151-156
[23]: http://github.com/tim/activerecord-diff
[24]: https://github.com/paper-trail-gem/paper_trail/blob/master/lib/paper_trail/serializers/yaml.rb
[25]: https://github.com/paper-trail-gem/paper_trail/blob/master/lib/paper_trail/serializers/json.rb
[26]: http://www.postgresql.org/docs/9.4/static/datatype-json.html
[27]: https://github.com/rspec/rspec
[28]: http://cukes.info
[29]: https://github.com/sporkrb/spork
[30]: https://github.com/burke/zeus
[31]: https://github.com/rails/spring
[32]: http://api.rubyonrails.org/classes/ActiveRecord/AutosaveAssociation.html#method-i-mark_for_destruction
[33]: https://github.com/paper-trail-gem/paper_trail/wiki/Setting-whodunnit-in-the-rails-console
[34]: https://github.com/rails/rails/blob/591a0bb87fff7583e01156696fbbf929d48d3e54/activerecord/lib/active_record/fixtures.rb#L142
[35]: https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html
[36]: http://www.postgresql.org/docs/9.4/interactive/ddl.html
[37]: https://github.com/ankit1910/paper_trail-globalid
[38]: https://github.com/sferik/rails_admin
[39]: http://api.rubyonrails.org/classes/ActiveRecord/Base.html#class-ActiveRecord::Base-label-Single+table+inheritance
[40]: http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#module-ActiveRecord::Associations::ClassMethods-label-Polymorphic+Associations
[41]: https://github.com/jaredbeck/paper_trail-sinatra
[42]: https://github.com/activeadmin/activeadmin/wiki/Auditing-via-paper_trail-%28change-history%29
[43]: https://github.com/paper-trail-gem/paper_trail/blob/master/.github/CONTRIBUTING.md
[44]: https://github.com/globalize/globalize-versioning
[45]: https://github.com/globalize/globalize
[46]: https://github.com/fusion94/paper_trail_manager
[47]: https://github.com/solidusio-contrib/solidus_papertrail
[48]: https://github.com/nielsgl/sequelize-paper-trail
[49]: https://github.com/ankit1910/paper_trail-globalid
[50]: https://github.com/izelnakri/paper_trail
[51]: https://github.com/rikkipitt/rails_admin_history_rollback
[52]: http://guides.rubyonrails.org/active_record_callbacks.html
