require 'securerandom'

class FacebookPlugin < Rubko::Plugin
	def init
		@home = "http://#{url.host}/"
		config
	end

	attr_accessor :id, :secret, :home
	attr_reader :token

	# PART 1: Initiate login, ask user for permissions
	def start
		SecureRandom.hex(16).tap { |state|
			url.redirect build 'https://www.facebook.com/dialog/oauth', query.merge({
				scope: 'email,publish_stream', state: state
			})
		}
	end

	# PART 2: Return user data, populate @token
	def login(state, str)
		raise 'Please supply the return value of #start to #login' unless state

		params = parse str
		return false if state != params['state']

		code = params['code']
		url = build 'https://graph.facebook.com/oauth/access_token', query.merge({
			client_secret: secret, code: code
		})
		@token = parse( httpGet url )['access_token']

		jsonParse httpGet build 'https://graph.facebook.com/me', access_token: token
	end

private

	def parse(str)
		Rack::Utils.parse_query str
	end

	def build(url, hash)
		url + '?' + Rack::Utils.build_query(hash)
	end

	def query
		{client_id: id, redirect_uri: home}
	end
end