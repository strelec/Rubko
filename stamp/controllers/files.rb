require 'rubko/asset'

class FilesController < Rubko::Controller
	include Rubko::Asset

	def hit(*path)
		# do nothing special
	end

	def cache(*path)
		# do nothing
	end

	index def missing(*path)
		"File #{path * '/'} doesn't exist."
	end
end