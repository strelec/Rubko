require 'rubko'

#\ -w -p 8080

Signal.trap('USR1') {
	GC.start
}

#use Rack::CommonLogger
use Rack::Runtime

case ENV['RACK_ENV'].to_sym
when :development

	use Rack::Reloader, 0
	use Rack::ShowExceptions
	use Rack::Runtime
	#use Rack::Lint

	require 'sass/plugin/rack'
	use Sass::Plugin::Rack
	Sass::Plugin.options.merge!(
		style: :compressed,
		cache: false,
		template_location: {
			'./public/css/.private' => './public/css'
		},
		full_exception: false
	)

when :production

	# no, because we already do it
	#use Rack::ContentLength

end

run Rubko.new