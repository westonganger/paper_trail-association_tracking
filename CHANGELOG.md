# CHANGELOG

### Unreleased - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v2.2.1...master)
- Nothing yet 

### v2.2.1 - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v2.2.0...v2.2.1)
- [PR #38](https://github.com/westonganger/paper_trail-association_tracking/pull/38) - Fix the issue where reifying has_one association with `dependent: :destroy` could destroy a live record

### v2.2.0 - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v2.1.3...v2.2.0)

- [PR #36](https://github.com/westonganger/paper_trail-association_tracking/pull/36) - Fix load order for paper_trail v12+
- Drop support for Ruby 2.5
- Add Github Actions CI supporting multiple version of Ruby, Rails and multiple databases types

### 2.1.3 - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v2.1.1...v2.1.3)

- [PR #24](https://github.com/westonganger/paper_trail-association_tracking/pull/24) - Fix reification on STI models that have parent child relationships

### 2.1.2

- A late night oopsies, Release yanked immediately, had bug preventing installation.

### 2.1.1 - 2020-10-21 - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v2.1.0...v2.1.1)

- Bug fix for reify on `has_many :through` relationships when `:source` is specified
- Bug fix for reify on `has_many :through` relationships where the association is a has_one on the through model
- Bug fix to ensure install generator will set `PaperTrail.association_tracking = true`

### 2.1.0 - 2020-08-14 - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v2.0.0...v2.1.0)

- [PR #18](https://github.com/westonganger/paper_trail-association_tracking/pull/18) - Improve performance for `Model.reify(has_many: true)` by separating the SQL subquery.
- [PR #15](https://github.com/westonganger/paper_trail-association_tracking/pull/15) - Recreate `version_associations.foreign_key` index to utilize the new `version_associations.foreign_type` column
- Update test matrix to support multiple versions of PT-core and ActiveRecord
- Remove deprecated methods `clear_transaction_id`, `transaction_id` and `transaction_id=`

### 2.0.0 - 2019-01-22 - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v1.1.1...v2.0.0)

- [PR #11](https://github.com/westonganger/paper_trail-association_tracking/issues/11) - Remove null constraint on `version_associations.foreign_type` column which was added in `v1.1.0`. This fixes issues adding the column to existing projects who are upgrading.
- Add generator `rails g paper_trail_association_tracking:add_foreign_type_to_version_associations` for `versions_associations.foreign_type` column for upgrading applications from `v1.0.0` or earlier.

### How to Upgrade from v1.0.0 or earlier

- Run `rails g paper_trail_association_tracking:add_foreign_type_to_version_associations` and then migrate your database.

### 1.1.1 - 2018-01-14 - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v1.1.0...v1.1.1)

- Same as v2 release, this is released simply to maintain a working `v1` branch since `v1.1.0` was broken

### 1.1.0 - 2018-12-28 - [View Diff](https://github.com/westonganger/paper_trail-association_tracking/compare/v1.0.0...v1.1.0)

- Note: This release is somewhat broken, please upgrade to `v2.0.0` or stay on `v1.0.0`
- [PR #10](https://github.com/westonganger/paper_trail-association_tracking/pull/10) - The `has_many: true` option now reifies polymorphic associations. Previously they were skipped.
- [PR #9](https://github.com/westonganger/paper_trail-association_tracking/pull/9) - The `belongs_to: true` option now reifies polymorphic associations. Previously they were skipped.

### 1.0.0 - 2018-06-04

- [PT #1070](https://github.com/paper-trail-gem/paper_trail/issues/1070), [#2](https://github.com/westonganger/paper_trail-association_tracking/issues/2) - Extracted from paper_trail gem in v9.2
