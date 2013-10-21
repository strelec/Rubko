require 'faye/websocket'
require 'rubko/controller'

class Rubko::Socket < Rubko::Controller
	Faye::WebSocket.load_adapter 'thin'

	def initialize(*)
		super
		if Faye::WebSocket.websocket?(env)
			@ws = Faye::WebSocket.new env#, [], ping: 10*60
			@ws.onclose = -> event {
				p [:close, event.code, event.reason]
				@ws = nil
			}
		end
	end

	def finalize
		self.status, self.headers, self.body = *@ws.rack_response if @ws
	end

	def compressible?; false end
end