$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "police/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "police"
  s.version     = Police::VERSION
  s.authors     = ["Paul Hemberger"]
  s.email       = ["pwh@csail.mit.edu"]
  s.homepage    = "https://csail.mit.edu"
  s.summary     = "Police label prop with security contexts"
  s.description = "Secures your apps easy peasy"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.1.8"

  s.add_development_dependency "sqlite3"
end
