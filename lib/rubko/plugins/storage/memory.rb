require 'rubko/storage'

class MemoryStoragePlugin < Rubko::Storage

	@@data = {}

	def find(path)
		path.map { |x|
			escape x
		}.reduce( @@data ) { |v, k|
			v[k] || {}
		}
	end

	def escape(key)
		key.to_s
	end

	def unescape(key)
		key.to_sym
	end

	private :find, :escape, :unescape

	def [](*path)
		find(path)[nil]
	end

	def []=(*path, val)
		path.map! { |x| escape x }
		path.reduce( @@data ) { |v, k|
			v[k] ||= {}
			if k.equal? path.last # is the last element
				v[k][nil] = val
			end
			v[k]
		}
		val
	end

	def keys(*path)
		find(path).keys.compact.map { |x|
			unescape x
		}
	end

	def prune(*path)
		last = escape path.pop
		find(path).delete last
	end

	def rename(*path, name)
		name = escape name
		last = escape path.pop
		hash = find path
		return false if hash[name]
		hash[name] = hash.delete last
		true
	end
end