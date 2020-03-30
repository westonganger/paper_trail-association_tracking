# frozen_string_literal: true

# Specify here only version constraints that differ from
# `paper_trail.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don't need to repeat anything that's the same for each
# > appraisal. If something is specified in both the Gemfile and an appraisal,
# > the version from the appraisal takes precedence.
# > https://github.com/thoughtbot/appraisal

pt_versions = [
  '~>9.2', 
  '~>10.2', 
]

ar_versions = [
  ['~>5.2.0', pt_versions[0..-1]],
  ['~>6.0.0', pt_versions[0..-1]],
]

ar_versions.each do |ar_ver, compatible_pt_versions|
  compatible_pt_versions.each do |y|

    appraise "ar#{x} pt#{y}" do
      gem "paper_trail", y

      gem "activerecord", x

      gem "rails-controller-testing"
    end

  end
end
