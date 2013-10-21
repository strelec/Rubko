class Rubko::Asset::FileStream
	def initialize(path, chunk = 32)
		@path = path
		@chunk = 1024*chunk
	end

	def each
		File.open(@path, 'rb') { |f|
			while part = f.read(@chunk)
				yield part
			end
		}
	end

	def bytesize
		File.size @path
	end
end