class Dmx
	attr_accessor :file, :source_page, :file_type, :has_header, :name, :path, :keys
	attr_accessor :struct, :index, :numeric_key, :scheme
	attr_accessor :delimiter, :unique_delimiter

	def initialize(name)
		@name=name
	end

	def struct=(a)
		@keys = a
		@struct = Struct.new @name.capitalize, *a
	end

	def fields=(*args)
		self.struct = args
	end

	def index=(*args)
		@index=args
	end
	def indexes=(*args); @index=args; end
	def indexes; @index; end
	def delimiter; @delimiter || @unique_delimiter; end

	def finish_init
		if !@struct and @has_header
			header = open(filename) { |f| f.readline.strip.gsub("\357\273\277",'') }
			self.struct = if unique_delimiter
				header.split unique_delimiter
			else
				raise 'XXX'
			end.collect { |y| y.downcase.to_sym }
		end
	end

	def filename
		File.join(self.path, self.file)
	end

	def dump
		open(filename) do |f|
			f.readline if has_header
			f.each do |line|
				yield struct.new *line.split(unique_delimiter)
			end
		end
	end
end

def Dmx(name)
	@dmx = Dmx.new(name)
	@dmx.path = "in/#{name}"
	def method_missing(sym, *args)
		sym = "#{sym}=".to_sym if args.length > 0
		if @dmx.respond_to? sym
			@dmx.send sym, *args
		else
			sym
		end
	end
	load File.join @dmx.path, name+'.rb'
	undef :method_missing
	@dmx.finish_init
	return @dmx
end
