# frozen_string_literal: true

class String
	# flip bits in a binary string
	def flipBits(bin_str)
		bin_str.chars.map { |bit| bit == '1' ? '0' : '1' }.join('')
	end
end