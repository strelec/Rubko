require 'rubko/controller'
require 'zlib'

class Rubko::Asset < Rubko::Controller
	class GzipStream
		def initialize(body, mtime = Time.now)
			@body = body
			@gzip = Zlib::GzipWriter.new self
			@gzip.mtime = mtime
		end

		def each(&block)
			@writer = block
			@body.each { |part|
				@gzip.write part
				@gzip.flush
			}
		ensure
			@gzip.close
		end

		def write(data)
			@writer.call data
		end
	end
end