# frozen_string_literal: true

class String

	# flip bits in a binary string
	def flipBits()
		self.chars.map { |bit| bit == '1' ? '0' : '1' }.join('')
	end

	# convert bases: https://stackoverflow.com/questions/5772875/converting-hexadecimal-decimal-octal-and-ascii
	def convert_base(from, to)
		val = Integer(self, from).to_s(to)
		val = val.to_i if to == 10 # auto-convert to integer
	end
	
end