require 'rubko/base'

class Rubko::Controller
	include Rubko::Base

	def index
		'It works. Please create the index() method.'
	end

	def other(name, *args)
		loadController('error404').other name, args
	end

	def compressible?
		env['HTTP_ACCEPT_ENCODING'].to_s.split(',').map(&:strip).include? 'gzip'
	end
end