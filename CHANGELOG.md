# CHANGELOG

## 1.1.1 - Unreleased

- [#11](https://github.com/westonganger/paper_trail-association_tracking/issues/11) - Remove null constraint on `version_associations.foreign_type` column which was added in `v1.1.0`. This fixes issues adding the column to existing projects who are upgrading.
- Add generator `rails g paper_trail_association_tracking:add_foreign_type_to_version_associations` for `versions_associations.foreign_type` column for upgrading applications from `v1.0.0` or earlier.

### How to Upgrade from v1.0.0 or earlier

- Run `rails g paper_trail_association_tracking:add_foreign_type_to_version_associations` and then migrate your database.

## 1.1.0 - 2018-12-28

- [#10](https://github.com/westonganger/paper_trail-association_tracking/pull/9) - The `has_many: true` option now reifies polymorphic associations. Previously they were skipped.
- [#9](https://github.com/westonganger/paper_trail-association_tracking/pull/9) - The `belongs_to: true` option now reifies polymorphic associations. Previously they were skipped.

## 1.0.0 - 2018-06-04

- [PT #1070](https://github.com/paper-trail-gem/paper_trail/issues/1070), [#2](https://github.com/westonganger/paper_trail-association_tracking/issues/2) - Extracted from paper_trail gem in v9.2
