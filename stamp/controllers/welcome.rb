class WelcomeController < Rubko::Controller

	def index
		loadView :welcome
	end
end