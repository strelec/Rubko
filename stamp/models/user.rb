require 'digest/md5'

class UserModel < Rubko::Model

	def [](id, public = false)
		return unless id
		if public
			ret = db.row 'SELECT id, fbID, name, gender, rights, rating FROM users WHERE id=?', id
			ret.merge hash: Digest::MD5.hexdigest(ret[:name])
		else
			db.row 'SELECT * FROM users WHERE id=?', id
		end
	end
end