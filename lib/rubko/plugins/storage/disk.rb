require 'rubko/storage'
require 'fileutils'

class DiskStoragePlugin < Rubko::Storage

	def init
		@root = '.run/storage'
		@name = 'data.txt'
	end

	def escape(path)
		@root + '/' + path.map(&:to_s) * '/'
	end

	def unescape(key)
		key.to_sym
	end

	private :escape, :unescape

	def [](*path)
		data = File.read escape(path)+'/'+@name rescue return nil
		Marshal.load data rescue nil
	end

	def []=(*path, val)
		path = escape(path)
		FileUtils.mkpath path
		File.write path+'/'+@name, Marshal.dump(val)
		val
	end

	def keys(*path)
		Dir[ escape(path)+'/*/' ].map { |key|
			unescape File.basename(key)
		}
	end

	def prune(*path)
		FileUtils.rmtree escape(path), secure: true
		true
	end

	def rename(*path, name)
		new = escape(path[0..-2] + [name])
		return false if File.exist? new
		FileUtils.mv escape(path), new
		true
	end
end