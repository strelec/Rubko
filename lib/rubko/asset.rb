require "pathname"

class Rubko; module Asset

	def self.included(obj)
		obj.instance_variable_set :@root, [:public]
		obj.class_eval {
			def self.root(*path)
				@root = path
			end

			index def index(*path)
				# protect private files
				return if path.include?('..') || path.include?('.private') && production?

				dir = self.class.instance_variable_get :@root
				path.shift if path.first =~ /\A\d+\z/
				file = Pathname((dir+path) * '/')

				return unless file.file?

				self.mime = @mime = Rack::Mime.mime_type file.extname

				headers['Cache-Control'] = 'public'
				headers['Vary'] = 'Accept-Encoding'

				@modified = file.mtime
				since = (Time.httpdate(env['HTTP_IF_MODIFIED_SINCE']).to_i rescue 0)
				headers['Last-Modified'] = @modified.httpdate
				headers['Expires'] = (DateTime.now >> 12).httpdate

				if modified.to_i > since
					hit( *path )
					require 'rubko/asset/fileStream'
					FileStream.new file
				else
					cache( *path )
					self.status = 304
					''
				end
			end

			def hit; end
			def cache; end
		}
	end

	def compressible?
		return false unless mime
		super && mime != 'application/octet-stream' &&
		['application', 'text'].any? { |type|
			mime.start_with? type+'/'
		}
	end

	attr_reader :mime, :modified

end; end