require 'bdb'
require 'dmx'
require 'set'

DB_PATH='db'
MAX_RESULTS=20
$orig_stdout = $stdout
$orig_stderr = $stderr
$devnull = File.new('/dev/null', 'w')

class Db
	def initialize(filename)
		@env = Bdb::Env.new(0)
		@env_flags =  Bdb::DB_CREATE |    # Create the environment if it does not already exist.
		             #Bdb::DB_INIT_TXN  | # Initialize transactions
		             #Bdb::DB_INIT_LOCK | # Initialize locking.
		             #Bdb::DB_INIT_LOG  | # Initialize logging
		             Bdb::DB_INIT_MPOOL  # Initialize the in-memory cache.
		@env.open(File.join(File.dirname(__FILE__), DB_PATH), @env_flags, 0)

		@db = @env.db
		@db.flags = Bdb::DB_DUPSORT
		@db.open(nil, filename, nil, Bdb::Db::HASH, Bdb::DB_CREATE, 0) # | Bdb::DB_AUTO_COMMIT, 0)
		@txn = nil
	end

	def begin_transaction
		@txn = @env.txn_begin(nil, 0)
	end

	def commit
		@txn.commit(0)
		@txn = nil
	end
	
	def sync
		@db.sync
	end

	def get_all(key, max_results=MAX_RESULTS)
		data = []
		cursor = @db.cursor(nil, 0)
		ret = cursor.get(key, nil, Bdb::DB_SET)
		count = 0
		while ret and (count += 1) <= max_results
			data << ret[1]
			ret = cursor.get(key, nil, Bdb::DB_NEXT_DUP)
		end
		cursor.close
		return data
	end
	
	def push(key, value)
		@db.put(@txn, key, value, 0)
	rescue Bdb::DbError => e
		raise unless e.code == -30995 # DB_KEYEXIST
	end

	def import_dmx(dmx) #(dmx_name)
		x=0
		#dmx = Dmx dmx_name
		dmx.dump do |row|
			dump = Marshal.dump row
			keys = Set.new
			for index in dmx.indexes
				#puts "Index: #{row.send(index)} Row: #{row}"
				key = row.send(index)
				key = key.downcase if key.respond_to? :downcase
				keys.add key
				puts "Row #{x}: #{key}" if x % 100 == 0
				self.push key, dump unless keys.include? key
				x+=1
			end
			if dmx.numeric_key
				self.push "#{dmx.scheme}:#{row.send(dmx.numeric_key)}", dump
			end
		end
		self.sync
	end
end

#  load 'db.rb'; db = Db.new 'data'; dmx = Dmx 'gnis'; db.import_dmx dmx
#db = Db.new 'data'
#dmx = Dmx 'gnis'
#db.import_dmx dmx

if ARGV[0] == 'import'
	db = Db.new 'data'
	db.import_dmx Dmx(ARGV[1])
elsif ARGV[0] == 'testimport'
	db = Db.new 'testdata'
	db.import_dmx Dmx(ARGV[1])
end