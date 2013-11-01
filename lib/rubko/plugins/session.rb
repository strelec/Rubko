require 'securerandom'

class SessionPlugin < Rubko::Plugin
	def init
		@name = :session	# cookie name
		@timeout = 2*60*60	# session timeout in seconds of inactivity
		@purgeRate = 10_000	# interval (requests) to clear expired sessions
		@hashSize = 16		# entropy of hash in byes

		@storage = memory
		@cookie = loadPlugin :cookie
	end

	def id
		if @id.nil?
			config
			purge if 0 == rand(purgeRate)

			@id = if ip?
				cookie.ip
			else
				cookie[name] || false
			end

			if @id
				if time = storage[name, @id]
					destroy if Time.now - time > @timeout
				end
				storage[name, @id] = Time.new
			end
		end
		@id
	end

	attr_accessor :name, :path, :timeout, :purgeRate, :hashSize, :storage, :cookie

	def ip?
		name == :ip
	end

	def purge
		storage.values(name).each { |id, time|
			destroy if Time.now - time > timeout
		}
	end

	def create
		return if id
		cookie[name] = @id = hash unless ip?
		storage[name, @id] = Time.new
	end

	def destroy
		return unless id
		storage.prune name, id
		cookie[name] = nil
		@id = false
	end

	def hash
		SecureRandom.urlsafe_base64 hashSize
	end

	def resid
		return if ip? || !id
		storage.rename name, id, (cookie[name] = hash)
	end

	private :hash

	def []=(*args, val)
		create
		return unless id
		storage[name, id, *args] = val
	end

	def self.delegate(*funcs)
		funcs.each { |func|
			define_method(func) { |*args|
				sid = id
				storage.send func, name, sid, *args
			}
		}
	end

	delegate :[], :keys, :prune, :rename
	delegate :values, :inspect
end