class WelcomeController < Rubko::Controller

	# GET /
	index def x
		loadView :welcome
	end

	# POST /
	create def y
		"You have just created new user!"
	end


	# GET /user/John
	get def user(name)
		"Hello, my name is #{name}!"
	end

	# GET /user/20
	get :user, Integer, def z(id)
		"Hello, my ID is #{id}."
	end

	# GET /image/small.JPG
	get :image, /(.*)\.jpg/i, def img(basename)
		"You've requested the #{basename}.jpg"
	end


	# PATCH /20/Mathew
	# PUT /20/Mathew
	update def update_function(id, name='Luke')
		""
	end

	# DELETE /20
	destroy def destroy_function(id)
		"Goodbye, says #{id}."
	end
end