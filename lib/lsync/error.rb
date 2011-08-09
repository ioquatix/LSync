# Copyright (c) 2007, 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module LSync

	# Base exception class which keeps track of related components.
	class Error < StandardError
		def initialize(reason, components = {})
			@reason = reason
			@components = components
		end

		def to_s
			@reason
		end

		attr :reason
		attr :components
	end

	# Indicates that there has been a major backup script error.
	class ScriptError < Error
	end

	# Indicates that there has been a major backup method error.
	class BackupMethodError < Error
	end

	# Indicates that a backup action shell script has failed.
	class CommandFailure < Error
		def initialize(command, status)
			super("Command #{command.inspect} failed with exit status #{status}", :command => command, :status => status)
		end
	end
end