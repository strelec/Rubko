class Error404Controller < Rubko::Controller
	def index
		other
	end

	def other(name = nil, *path)
		notFound # or #redirect
		self.mime = 'text/plain'
		"404 \n" + ([name]+path)*' / '
	end

	def notFound
		self.status = 404
	end

	def redirect
		url.redirect
	end
end