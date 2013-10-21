require './lib/rubko'

Gem::Specification.new do |gem|
	gem.name        = 'rubko'
	gem.version     = Rubko::VERSION
	gem.date        = Date.today.to_s
	gem.license     = 'GPL'

	gem.summary     = 'Web framework'
	gem.description = 'Simple and amazingly fast ruby web framework.'

	gem.authors     = ['Rok Kralj']
	gem.email       = 'ruby@rok-kralj.net'
	gem.homepage    = 'https://github.com/strelec/Rubko'

	files = `git ls-files -z`
	files = `find ./*` if files.empty?
	gem.files       = files.split "\n"
	gem.executables << 'rubko-deploy'

	gem.add_dependency 'json'
end