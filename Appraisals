# Specify here only version constraints that differ from `paper_trail.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don't need to repeat anything that's the same for each
# > appraisal. If something is specified in both the Gemfile and an appraisal,
# > the version from the appraisal takes precedence.
# > https://github.com/thoughtbot/appraisal

### WHEN UPDATING THESE VERSIONS DONT FORGOT TO UPDATE .github/workflows/test.yml
pt_versions = [
  '~>12.0', 
]

ar_versions = [
  [
    '~>5.2', 
    pt_versions,
  ],
  [
    '~>6.0', 
    pt_versions,
  ],
  [
    '~>6.1', 
    pt_versions,
  ],
]

ar_versions.each do |ar_ver, compatible_pt_versions|
  compatible_pt_versions.each do |pt_ver|
    appraise "ar_#{ar_ver.sub('~>','')} pt_#{pt_ver.sub('~>','')}" do
      gem "activerecord", ar_ver

      if pt_ver == 'master'
        gem "paper_trail", git: 'https://github.com/paper-trail-gem/paper_trail.git'
      else
        gem "paper_trail", pt_ver
      end

      gem "rails-controller-testing"
    end

  end
end
