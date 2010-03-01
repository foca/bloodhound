Gem::Specification.new do |s|
  s.name    = "bloodhound"
  s.version = "0.3.1"
  s.date    = "2010-03-01"

  s.description = "Map strings like 'user:foca age:23' to ActiveRecord named_scopes"
  s.summary = "Map strings like 'user:foca age:23' to ActiveRecord named_scopes"
  s.homepage    = "http://github.com/foca/bloodhound"

  s.authors = ["Nicolás Sanguinetti"]
  s.email   = "contacto@nicolassanguinetti.info"

  s.require_paths     = ["lib"]
  s.has_rdoc          = false

  s.files = %w[
.gitignore
README.markdown
bloodhound.gemspec
lib/bloodhound.rb
spec/spec_helper.rb
spec/bloodhound_spec.rb
]
end

