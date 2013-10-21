class CookiePlugin < Rubko::Plugin
	def init
		@domain = nil
		@path = url.base
		@httpOnly = true
		@secure = false

		@maxAge = 30*24*60*60
		@expires = nil
		config
	end

	attr_accessor :domain, :path, :httpOnly, :secure, :maxAge, :expires

	def cookies
		return @cookies if @cookies
		return @cookies = {} unless env['HTTP_COOKIE']

		@cookies = Rack::Utils.parse_query(env['HTTP_COOKIE'], ';,').
		inject({}) { |h, (k,v)|
			h.tap { |x|
				x[k.to_sym] = (Array === v) ? v.first : v
			}
		}
	end
	private :cookies

	def ip
		Rack::Request.new(env).ip.encode 'UTF-8'
	end

	def [](key = nil)
		key.nil? ? cookies : cookies[key]
	end

	def []=(key, val)
		if val.nil?
			Rack::Utils.delete_cookie_header! headers, key, domain: domain, path: path
		else
			Rack::Utils.set_cookie_header! headers, key, value: val, domain: domain, path: path,
			httponly: httpOnly, secure: secure, max_age: maxAge.to_s, expires: expires
		end
		val
	end
end