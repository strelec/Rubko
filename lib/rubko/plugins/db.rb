require 'pg'

class DbPlugin < Rubko::Plugin
	def init
		@host = ''
		@port = 5432
		@user = 'postgres'
		@password = ''
		@db = 'postgres'

		@pool = nil
	end

	def handle
		unless @handle
			config if @handle.nil?
			if @pool
				@sig = [@host, @port, @user, @password, @db]
				@handle = ( @pool[:db, *@sig] ||= [] ).pop
			end
			@handle = connect unless @handle
		end
		@handle
	end

	attr_accessor :host, :port, :user, :password, :db, :pool
	attr_reader :affectedRows

	def connect
		PG.connect host: @host, port: @post, user: @user, password: @password, dbname: @db
	end

	def release
		return true unless @handle
		if @pool && handle.transaction_status == 0
			@pool[:db, *@sig].push @handle
			@handle = false
			return true
		end
	end

	def poolSize
		@pool.keys(:db, *@sig).size
	end

	# PostgreSQL array OIDs and coresponding data type
	TypArray = {
		1000 => 16, # bool
		1001 => 17, # bytea
		1002 => 18, # char
		1003 => 19, # name
		1016 => 20, # int8
		1005 => 21, # int2
		1006 => 22, # int2vector
		1007 => 23, # int4
		1008 => 24, # regproc
		1009 => 25, # text
		1028 => 26, # oid
		1010 => 27, # tid
		1011 => 28, # xid
		1012 => 29, # cid
		1013 => 30, # oidvector
		199 => 114, # json
		143 => 142, # xml
		1017 => 600, # point
		1018 => 601, # lseg
		1019 => 602, # path
		1020 => 603, # box
		1027 => 604, # polygon
		629 => 628, # line
		651 => 650, # cidr
		1021 => 700, # float4
		1022 => 701, # float8
		1023 => 702, # abstime
		1024 => 703, # reltime
		1025 => 704, # tinterval
		719 => 718, # circle
		791 => 790, # money
		1040 => 829, # macaddr
		1041 => 869, # inet
		1034 => 1033, # aclitem
		1014 => 1042, # bpchar
		1015 => 1043, # varchar
		1182 => 1082, # date
		1183 => 1083, # time
		1115 => 1114, # timestamp
		1185 => 1184, # timestamptz
		1187 => 1186, # interval
		1270 => 1266, # timetz
		1561 => 1560, # bit
		1563 => 1562, # varbit
		1231 => 1700, # numeric
		2201 => 1790, # refcursor
		2207 => 2202, # regprocedure
		2208 => 2203, # regoper
		2209 => 2204, # regoperator
		2210 => 2205, # regclass
		2211 => 2206, # regtype
		2287 => 2249, # record
		1263 => 2275, # cstring
		2951 => 2950, # uuid
		2949 => 2970, # txid_snapshot
		3643 => 3614, # tsvector
		3645 => 3615, # tsquery
		3644 => 3642, # gtsvector
		3735 => 3734, # regconfig
		3770 => 3769, # regdictionary
		3905 => 3904, # int4range
		3907 => 3906, # numrange
		3909 => 3908, # tsrange
		3911 => 3910, # tstzrange
		3913 => 3912, # daterange
		3927 => 3926, # int8range
	}

	def castArray(value, type)
		size, _, type = *value[0, 3*4].unpack('l>*')
		return [] if size == 0

		dims = value[3*4, 2*4*size].unpack('l>*').each_slice(2).map {
			|x| x[0]
		}

		i = 3*4 + 2*4*size
		data = dims.reduce(:*).times.map {
			size = value[i, 4].unpack('l>')[0]
			i += 4 + size
			cast value[ i-size, size ], type
		}

		dims.reverse.reduce(data) { |orig, dim|
			orig.each_slice dim
		}.to_a[0]
	end

	Unpack = {
		16 => 'C', # bool
		21 => 's>', # int2
		23 => 'l>', # int4
		20 => 'q>', # int8
		26 => 'L>', # oid
		700 => 'g', # float4
		701 => 'G', # float8
		829 => 'C*', # macaddr
		1082 => 'l>', # date
		1114 => 'q>', # timestamp
		1184 => 'q>', # timestamptz
		1186 => 'q>l>l>', # interval
		1700 => 's>*', # numeric

		1007 => 'l>*'
	}

	def castNumeric(value)
		_, fac, sign, scale, *digits = value
		return Float::NAN if sign == -16384

		sign = (sign == 0 ? '': '-')
		value = digits.map { |digit|
			'%04d' % digit
		}

		if scale != 0
			require 'bigdecimal'
			BigDecimal.new sign + value.insert(fac+1, '.').join
		else
			( sign + value.join + '0000'*fac ).to_i
		end
	end

	def cast(value, type)
		return if value.nil?

		if TypArray.key? type
			return castArray value, TypArray[type]
		end

		if Unpack.key? type
			value = value.unpack Unpack[type]
		end

		case type
		when 16 # bool
			value[0] == 1
		when 17 # bytea
			value
		when 25, 1042, 1043, 18, 19 #text, bpchar, varchar, char, name
			value.force_encoding 'UTF-8'
		when 1700 # numeric
			castNumeric value
		when 114 # json
			JSON.parse value, symbolize_names: true
		when 1082 # date
			Date.new(2000) + value[0]
		when 1114, 1184 # timestamp, timestamptz
			Time.gm(2000) + value[0]/1_000_000.0
		when 1186 # interval
			TimeInterval.new( *value.reverse )
		when 829 # macaddr
			value.map { |x| '%02x' % x } * ':'
		when 869 # inet
			require 'ipaddr'
			ip = IPAddr.ntop value[4..-1]
			IPAddr.new "#{ip}/#{value[1].ord}"
		when 2278, 705 # void, unknown
			nil
		else
			return value[0] if Unpack.key? type
			throw "Invalid OID type of #{type} (#{value})" if type < 16384
			value
		end
	end

	def castHash(hash, result)
		Hash[ hash.map.with_index { |(key, value), i|
			[ key.to_sym, cast(value, result.ftype(i)) ]
		} ]
	end

	private :cast, :castHash, :castArray

	def escape(param, type = nil)
		case param
		when Array
			'(' + param.map { |element|
				escape element
			}.join(',') + ')'
		when String
			if param.encoding.name == 'ASCII-8BIT'
				"'" + handle.escape_bytea(param) + "'"
			else
				"'" + handle.escape_string(param) + "'"
			end
		when Symbol
			handle.quote_ident param.to_s
		when Integer, Float, TimeInterval, FalseClass, TrueClass
			param.to_s
		else
			'NULL'
		end
	end

	def prepare(query, *args)
		hash = args[-1].kind_of?(Hash) && args.pop || {}
		hash.merge! Hash[(0...args.size).zip args]

		i = -1
		query.gsub(/[[:alpha:]]+/i) { |match|
			( match =~ /[[:upper:]]/ && match =~ /[[:lower:]]/ ) ? escape(match.to_sym) : match
		}.gsub(/\?(\w+)?\??([b])?/) { |match|
			key = $1 || i += 1
			key = key.to_sym if key.respond_to? :to_sym
			key = key.to_s unless hash.has_key? key

			hash.has_key?(key) && escape(hash[key], $2) || match
		}.tap { |out| log.sql out.gsub(/\s+/, ' ') }
	end

	def raw(query, *args)
		handle.exec prepare(query, *args), [], 1
	end

	def value(query, *args)
		result = raw query, *args
		cast(result.getvalue(0, 0), result.ftype(0)) if result.ntuples > 0
	end

	def row(query, *args)
		result = raw query, *args
		castHash result[0], result if result.ntuples > 0
	end

	def column(query, *args)
		result = raw query, *args
		return [] if result.nfields == 0
		result.column_values(0).map { |value|
			cast value, result.ftype(0)
		}
	end

	def result(query, *args, &block)
		result = raw(query, *args)
		if block
			result.each { |row|
				yield castHash row, result
			}
		else
			result.map { |row|
				castHash row, result
			}
		end
	end

	def resultHash(key, query, *args)
		ret = {}
		result = raw query, *args
		result.each { |row|
			row = castHash row, result

			[*key].reduce(ret) { |v, k|
				bucket = row.delete k.to_sym
				v[bucket] ||= {}
			}.replace row
		}
		ret
	end

	def resultMultiHash(key, query, *args)
		ret = {}
		result = raw query, *args
		result.each { |row|
			row = castHash row, result

			last = [*key].last
			[*key].reduce(ret) { |v, k|
				bucket = row.delete k.to_sym
				if k.equal? last # is the last element
					( v[bucket] ||= [] ) << row
				else
					v[bucket] ||= {}
				end
			}
		}
		ret
	end

	def transaction(mode = nil)
		begin
			raw 'BEGIN' + (' ISOLATION LEVEL '+mode if mode).to_s
				yield
			raw 'COMMIT' if inTransaction
		rescue => e
			puts e
			puts e.backtrace
			rollback
			puts 'Transaction rolled back.'
		end
	end

	def rollback
		raw 'ROLLBACK'
	end

	def inTransaction
		handle.transaction_status == 2
	end

	def finalize
		unless release
			handle.finish unless handle.finished?
		end
	end
end

class TimeInterval
	# this class directly adheres to Postgres's internal INTERVAL representation

	def initialize(mon, day, usec)
		@mon = mon
		@day = day
		@usec = usec
	end

	attr_accessor :mon, :day, :usec

	def to_s
		"#{mon}mon #{day}day #{usec}usec"
	end

	def +(time)
		( (time >> mon) + day ).to_time + usec/1_000_000.0
	end

	def to_time
		self + DateTime.new(1970)
	end

	def to_f
		to_time.to_f
	end

	def to_i
		to_time.to_i
	end

	def to_json(*)
		to_f.to_s
	end
end