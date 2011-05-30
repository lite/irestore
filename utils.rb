def rand_hex_3(l)
  "%0#{l}x" % rand(1 << l*4)
end

def gen_uuid
  [8,4,4,4,12].map {|n| rand_hex_3(n)}.join('-')
end

class String
  def hexdump
    buffer = ""
    (0..length).step(16) do |i|
      first_half = self[i, 8].unpack("C*").map{|x| "%02x" % x}.join(" ")
      second_half = (self[i + 8, 8] || "").unpack("C*").map{|x| "%02x" % x}.join(" ")
      first_half += " " * (8 * 2 + (8 - 1) - first_half.length)
      second_half += " " * (8 * 2 + (8 - 1) - second_half.length)
      buffer += first_half + "  " + second_half + "\t" + self[i, 16].unpack("C*").map{|x| ((32..128).include?(x) ? x : ?.).chr}.join + "\n"
    end
    puts buffer
  end
  
  def printable?
    self.unpack("C*").all?{|x| ((32..128).entries + [9, 10]).include?(x)}
  end
  
  # def to_hex
  #   self.unpack("C*").map{|x| "%02x" % x}.join
  # end

	def to_hex
		self.unpack("H*")[0] 
	end   
	
  def from_hex  
    [self].pack("H*")
  end
end
     

