require 'bit-struct'
require 'pp' 

class Header < BitStruct 
	default_options :endian=>:native
  unsigned    :signature,      	32,     "signature"
  unsigned    :full_size,       32,     "full_size"
  unsigned    :data_size,       32,     "data_size"
  unsigned    :shsh_offset,     32,     "shsh_offset"
  unsigned    :image_type,      32,     "image_type"
end
   
class ElementHeader < BitStruct
	default_options :endian=>:native
  unsigned    :signature,      	32,     "signature"
  unsigned    :full_size,       32,     "full_size"
  unsigned    :data_size,       32,     "data_size"    
end

class Element < BitStruct
	default_options :endian=>:native
  nest 				:header, 									ElementHeader	   
  rest        :data,       							"data"  
end
   
class Img3File
	attr_accessor :header, :elements, :elementkeys
	
	def parse(input)        
		data = input.read(Header.round_byte_length) 
		@header = Header.new  data
	 	@elements, @elementkeys = self.parse_elements(input, @header.full_size)
	end

	def parse_elements(input, total_len)
		elements = []        
		elementkeys = [] 
		#  
		pos = Header.round_byte_length
		while pos < total_len do 
			#p "#{pos}/#{@header.full_size}"  
			data = input.read(ElementHeader.round_byte_length)
			if data.nil? 
				break
			end
			h = ElementHeader.new data
			elementkeys += [h.signature] 
			element = Element.new
			element.header = h
			element.data = input.read(h.full_size-ElementHeader.round_byte_length)
			elements += [element]
			pos += h.full_size
	 	end
		# self
		[elements, elementkeys]            
	end
	
	def update_elements(input, total_len)        
		# parse
		elements, elementkeys = parse_elements(input, total_len) 
		pp elementkeys
		# update keys
		tmp = []
		@elements.each do |e|
			if not elementkeys.include?(e.header.signature)
				tmp += [e]
			end
		end
		# update 
		@elements = tmp + elements
		@elementkeys = elementkeys            
	end
	
	def to_s
		tmp = StringIO.new
		header = Header.new
		pos = 0
		@elements.each do |e|
			#p "#{pos}/#{@header.full_size} #{e.header.signature}"  
			if e.header.signature == "SHSH".reverse.unpack("i*")[0] # 0x53485348, 1397248840 
			# 53485348
				header.shsh_offset = pos
			end
			tmp << e.to_s
			pos += e.header.full_size
		end
		header.signature = @header.signature
		header.full_size = pos + Header.round_byte_length
	  header.data_size = pos
	  header.image_type = @header.image_type
		
		output = StringIO.new
		output << header.to_s
		output << tmp.string
		output.rewind
		output.read
	end
   
end
                                        
