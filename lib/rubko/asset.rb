require 'rubko/controller'

# in case we want to serve files and get notified on hits
class Rubko::Asset < Rubko::Controller

	def init
		@dir = 'public'
	end

	attr_accessor :dir

	def hit(*path)
		puts "File #{path*'/'} hit." unless production?
	end

	def cache(*path)
	end

	def miss(*path)
		puts "File #{path*'/'} not found (404)."
		loadController(:error404).other( *path )
	end

	private :hit, :cache, :miss

	def compressible?
		super && @mime != 'application/octet-stream' &&
		['application', 'text'].any? { |type|
			@mime.start_with? type+'/'
		}
	end

	attr_reader :mime, :modified

	def index
		other
	end

	def other(*path)
		# protect private files
		if path.include?('..') || path.include?('.private') && production?
			return miss(*path)
		end

		path.shift if path[0] =~ /^\d*$/
		path = "#{@dir}/#{path * '/'}"
		@mime = Rack::Mime.mime_type File.extname(path)
		if File.file? path
			self.mime = @mime
			headers['Cache-Control'] = 'public'
			headers['Vary'] = 'Accept-Encoding'

			@modified = File.mtime path
			since = (Time.httpdate(env['HTTP_IF_MODIFIED_SINCE']).to_i rescue 0)
			headers['Last-Modified'] = @modified.httpdate
			headers['Expires'] = (DateTime.now >> 12).httpdate

			if @modified.to_i <= since
				cache( *path )
				self.status = 304
				''
			else
				hit( *path )
				require 'rubko/asset/fileStream'
				FileStream.new path
			end
		else
			miss( *path )
		end
	end
end