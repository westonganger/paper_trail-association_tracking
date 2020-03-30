# CHANGELOG

## Unreleased

- [PR #15](https://github.com/westonganger/paper_trail-association_tracking/pull/15) - Recreate `version_associations.foreign_key` index to utilize the new `version_associations.foreign_type` column
- Update test matrix to support multiple versions of PT-core and ActiveRecord

## 2.0.0 - 2019-01-22

- [PR #11](https://github.com/westonganger/paper_trail-association_tracking/issues/11) - Remove null constraint on `version_associations.foreign_type` column which was added in `v1.1.0`. This fixes issues adding the column to existing projects who are upgrading.
- Add generator `rails g paper_trail_association_tracking:add_foreign_type_to_version_associations` for `versions_associations.foreign_type` column for upgrading applications from `v1.0.0` or earlier.

### How to Upgrade from v1.0.0 or earlier

- Run `rails g paper_trail_association_tracking:add_foreign_type_to_version_associations` and then migrate your database.

## 1.1.1 - 2018-01-14

- Same as v2 release, this is released simply to maintain a working `v1` branch since `v1.1.0` was broken

## 1.1.0 - 2018-12-28

- Note: This release is somewhat broken, please upgrade to `v2.0.0` or stay on `v1.0.0`
- [PR #10](https://github.com/westonganger/paper_trail-association_tracking/pull/10) - The `has_many: true` option now reifies polymorphic associations. Previously they were skipped.
- [PR #9](https://github.com/westonganger/paper_trail-association_tracking/pull/9) - The `belongs_to: true` option now reifies polymorphic associations. Previously they were skipped.

## 1.0.0 - 2018-06-04

- [PT #1070](https://github.com/paper-trail-gem/paper_trail/issues/1070), [#2](https://github.com/westonganger/paper_trail-association_tracking/issues/2) - Extracted from paper_trail gem in v9.2
