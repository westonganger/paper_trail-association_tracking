# Specify here only version constraints that differ from `paper_trail.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don't need to repeat anything that's the same for each
# > appraisal. If something is specified in both the Gemfile and an appraisal,
# > the version from the appraisal takes precedence.
# > https://github.com/thoughtbot/appraisal

### WHEN UPDATING THESE VERSIONS DONT FORGOT TO UPDATE .github/workflows/test.yml
latest_pt_version = "~>12"

latest_pt_supported_ar_versions = [
  '~>5.2', 
  '~>6.0', 
  '~>6.1', 
  '~>7.0', 
]

legacy_pt_versions = [
  '~>9',
  '~>10',
  '~>11',
]

latest_pt_supported_ar_versions.each do |ar_ver|
  appraise "pt_#{latest_pt_version.sub('~>','')} ar_#{ar_ver.sub('~>','')}" do
    gem "paper_trail", latest_pt_version

    gem "activerecord", ar_ver
    gem "rails-controller-testing"
  end
end

legacy_pt_versions.each do |pt_ver|
  appraise "pt_#{pt_ver.sub('~>','')}" do
    gem "paper_trail", pt_ver

    gem "activerecord"
    gem "rails-controller-testing"
  end
end
