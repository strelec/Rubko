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
		@controller = loadController(name) || loadController(:error404)

		calls = [ action ? "_#{action}" : 'index' ]
		calls << calls.first + '_' + url.method

		calls.map! { |call|
			if @controller.respond_to? call
				@body = @controller.__send__ call, *path
				true
			end
		}
		if calls.compact.empty?
			@body = @controller.other action, *path
		end

		# finalize request
		finalizers.reverse_each(&:finalize)
		prepareBody!
		prepareHeaders!

		[@status, @headers, @body]
	end

	def production?
		ENV['RACK_ENV'] == 'production'
	end

private

	def prepareBody!
		# if object is a Hash, return JSON
		if Hash === @body
			@mime = 'application/json'
			@body = if production?
				@body.to_json
			else
				JSON.pretty_generate @body, indent: "\t"
			end
		end

		# make sure body responds to :each
		@body = @body.to_s if Integer === @body
		@body = [@body] if String === @body
		@body = [] unless @body.respond_to? :each
	end

	def prepareHeaders!
		# apply mime type header
		unless status == 304
			headers['Content-Type'] = "#{mime}; charset=utf-8"
		end

		# compress
		if @controller.compressible?
			headers['Content-Encoding'] = 'gzip'
			@body = Rubko::Asset::GzipStream.new body
		end

		# add Content-Length header
		headers['Content-Length'] = if body.respond_to? :bytesize
			body.bytesize
		elsif Array === @body
			body.reduce(0) { |sum, x|
				sum + x.bytesize
			}
		end

		# rack requires strings as values
		headers.each { |k, v|
			if v.nil?
				headers.delete k
			elsif not String === v
				headers[k] = v.to_s
			end
		}
	end
end