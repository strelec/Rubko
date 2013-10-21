require 'rubko/asset'

class FilesController < Rubko::Asset

	def init
		self.dir = 'public'
	end

	def hit(*path)
		# do nothing special
	end

	def cache(*path)
		# do nothing
	end

	def miss(*path)
		super
	end
end