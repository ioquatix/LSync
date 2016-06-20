# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

# This script takes a given path, and renames it with the given format. 
# It then ensures that there is a symlink called "latest" that points 
# to the renamed directory.

require_relative '../method'

require 'samovar'

require 'periodical/filter'

# Required for strptime
require 'date'

module LSync
	module Command
		class Rotation
			def initialize(path, time)
				@path = path
				@time = time
			end

			attr :time
			attr :path

			# Sort in reverse order by default
			def <=> other
				return other.time <=> @time
			end
			
			def eql? other
				case other
				when Rotation
					@path.eql?(other.path)
				else
					@path.eql?(other.to_s)
				end
			end
			
			def hash
				@path.hash
			end
			
			def to_s
				@path
			end
		end
		
		class Prune < Samovar::Command
				self.description = "Prune old backups to reduce disk usage according to a given policy."
				
				options do
					option "--hourly <count>", "Set the number of hourly backups to keep.", default: 24
					option "--daily <count>", "Set the number of daily backups to keep.", default: 7*4
					option "--weekly <count>", "Set the number of weekly backups to keep.", default: 52
					option "--monthly <count>", "Set the number of weekly backups to keep.", default: 12*3
					option "--quaterly <count>", "Set the number of weekly backups to keep.", default: 4*10
					option "--yearly <count>", "Set the number of weekly backups to keep.", default: 20
					
					option "--format <name>", "Set the name of the backup rotations, including strftime expansions.", default: BACKUP_NAME
					option "--latest <name>", "The name of the latest backup symlink.", default: LATEST_NAME
					
					option "--keep <youngest|oldest>", "Keep the younder or older backups within the same period division", default: 'oldest'
					
					option "--dry", "Print out what would be done rather than doing it."
				end
				
				def policy
					policy = Periodical::Filter::Policy.new
					
					policy << Hourly.new(@options[:hourly])
					policy << Daily.new(@options[:daily])
					policy << Weekly.new(@options[:weekly])
					policy << Monthly.new(@options[:monthly])
					policy << Quarterly.new(@optins[:quarterly])
					policy << Yearly.new(@options[:yearly])
					
					return policy
				end
				
				def current_backups
					backups = []
					
					Dir['*'].each do |path|
						next if path == @options[:latest]
						date_string = File.basename(path)

						begin
							backups << Rotation.new(path, DateTime.strptime(date_string, @options[:format]))
						rescue ArgumentError
							$stderr.puts "Skipping #{path}, error parsing #{date_string}: #{$!}"
						end
					end
					
					return backups
				end
				
				def dry?
					@options[:dry]
				end
				
				def print_rotation(keep, erase)
					puts "*** Dry Run ***"
					puts "\tKeeping:"
					keep.sort.each { |backup| puts "\t\t#{backup.path}" }
					puts "\tErasing:"
					erase.sort.each { |backup| puts "\t\t#{backup.path}" }
				end
				
				def perform_rotation(keep, erase)
					erase.sort.each do |backup|
						puts "Erasing #{backup.path}..."
						$stdout.flush

						# Ensure that we can remove the backup
						system("chmod", "-R", "ug+rwX", backup.path)
						system("rm", "-rf", backup.path)
					end
				end
				
				def invoke(parent, program_name: File.basename($0))
					backups = current_backups
					
					keep, erase = policy.filter(backups)
					
					# We need to retain the latest backup regardless of policy
					if latest = @options[:latest] and File.exist?(latest)
						path = Pathname.new(OPTIONS[:Latest]).realpath.basename.to_s
						latest_rotation = erase.find { |rotation| rotation.path == path }

						if latest_rotation
							puts "Retaining latest backup #{latest_rotation}"
							erase.delete(latest_rotation)
							keep << latest_rotation
						end

						if dry?
							print_rotation(keep, erase)
						else
							perform_rotation(keep, erase)
						end
					end
				end
		end
	end
end
