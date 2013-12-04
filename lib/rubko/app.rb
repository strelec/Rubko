require 'rubko/base'
require 'rubko/asset/gzipStream'

class Rubko::App
	include Rubko::Base

	def initialize(env, shared = nil)
		@status = 200
		@headers = {'Connection' => 'Keep-Alive', 'Date' => Time.now.httpdate}
		@mime = 'text/html'
		@body = ''

		@shared = shared
		@finalizers = []

		@env = env
		params = Rack::Utils.parse_nested_query @env['rack.input'].read
		@params = Hash[ params.map { |k, v|
			[ k.to_sym, v ]
		} ]

		super()
	end

	attr_accessor :status, :headers, :mime, :body
	attr_reader :env, :params, :shared, :finalizers

	def init(path)
		url.path = path
		request( *url.newPath )
	end

	def request(name = :welcome, action = nil, *path)
		controller = loadController(name) || loadController(:error404)

		calls = [ action ? "_#{action}" : 'index' ]
		calls << calls.first + '_' + url.method

		calls.map! { |call|
			if controller.respond_to? call
				@body = controller.__send__ call, *path
				true
			end
		}
		if calls.compact.empty?
			@body = controller.other action, *path
		end

		# finalize request
		finalizers.reverse_each(&:finalize)
		@headers['Content-Type'] = "#{mime}; charset=utf-8" unless @status == 304

		# make sure body responds to :each
		@body = @body.to_s if Integer === @body
		@body = @body.to_json if Hash === @body

		@body = [@body] if String === @body
		@body = [] unless @body.respond_to? :each

		# compress
		if controller.compressible?
			headers['Content-Encoding'] = 'gzip'
			@body = Rubko::Asset::GzipStream.new @body
		end

		# add Content-Length header
		if @body.respond_to? :bytesize
			headers['Content-Length'] = @body.bytesize.to_s
		elsif Array === @body
			headers['Content-Length'] = @body.reduce(0) { |sum, x|
				sum + x.bytesize
			}.to_s
		end

		[@status, @headers, @body]
	end

	def production?
		ENV['RACK_ENV'] == 'production'
	end
end