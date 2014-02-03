class Error404Controller < Rubko::Controller

	get def index(*path)
		notFound # or #redirect
		self.mime = 'text/plain'
		"Not found:\n" + path*' / '
	end

	def notFound
		self.status = 404
	end

	def redirect
		url.redirect
	end
end