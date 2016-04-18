Gem::Specification.new do |spec|
  spec.name = "queueup"
  spec.version = "0.0.0"
  spec.executables << "queueup"
  spec.date = "2016-04-17"
  spec.summary = "A browser-based music player for trees of MP3s"
  spec.authors = ["D Rench"]
  spec.email = "queueup@dren.ch"
  spec.files = ["lib/queueup.rb"]
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_runtime_dependency "taglib-ruby"
  spec.homepage = "https://github.com/drench/queueup"
  spec.license = "MIT"
end
