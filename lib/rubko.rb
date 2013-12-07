require 'rubko/app'

class Rubko
	VERSION = '0.2'

	def initialize(shared = {})
		@shared = shared

		Dir['./includes/**/*.rb'].each { |file|
			require file
		}
		puts 'Server started successfully.'
	end

	# do not USE !
	def threaded
		EM.threadpool_size = 50
		-> env {
			EM.defer(
				-> { call env },
				-> r { env['async.callback'].call r }
			)
			throw :async
		}
	end

	def call(env)
		abort if env['rack.multithread']
		app = Rubko::App.new env, @shared
		app.init env['REQUEST_URI'].encode 'utf-8'
	end
end