require 'rubko/base'
require 'rubko/controller/macros'

class Rubko::Controller
	include Rubko::Base

	def self.inherited(obj)
		obj.extend Macros
		obj.instance_variable_set :@verbs, Hash.new { |h, k|
			h[k] = []
		}
	end

	def send(*params)
		verb = env['REQUEST_METHOD'].downcase.to_sym
		target = self.class.instance_variable_get(:@verbs)[verb]

		body = nil
		params.size.downto(0) { |i|
			if body.nil? && !target[i].nil?
				target[i].each { |sign|
					if match = sign.match(params)
						body = begin
							sign.call self, match
						rescue ArgumentError
							nil
						end
					end
				}
			end
		}
		body
	end

	def compressible?
		env['HTTP_ACCEPT_ENCODING'].to_s.split(',').map(&:strip).include? 'gzip'
	end

end