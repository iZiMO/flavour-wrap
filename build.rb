
class BuildConfig

	def initialize(flavour, sign)
		@flavour = flavour
		@sign = sign
	end

	attr_reader :flavour
	attr_reader :sign
end

class Builder

	@@top_level = %x[git rev-parse --show-toplevel].gsub(/\n/, "")
	@@project_directory = @@top_level + '/project/'
	@@res_folder = @@project_directory + 'res/'
	@@bin_folder = @@project_directory + 'bin/'
	@@flavour_folder = @@top_level + '/flavours/'
	@@output_folder = @@top_level + '/builds/'

	def initialize()
		@results = Hash.new
	end

	def copyResources(config)
		path = @@flavour_folder + config.flavour + '/'

		puts 'Copying resources for ' + config.flavour
		puts %x[cp -r #{path} #{@@project_directory}]
	end

	def build(config)

		copyResources(config)

		Dir.chdir @@project_directory do
			pipe = IO.popen('ant clean debug')
			while (line = pipe.gets)
				print line
			end
			pipe.close
		end

		if $?.exitstatus != 0
			return false
		end

		if config.sign
			pipe = IO.popen(@@top_level + '/signProjectAPK.sh')
			while (line = pipe.gets)
				print line
			end
			pipe.close
		end

		if $?.exitstatus != 0
			return false
		end

		storeArtifacts(config)

		return true
	end

	def storeArtifacts(config)
		folder = @@output_folder + config.flavour
		puts %x[mkdir #{folder}]
		Dir.glob(@@bin_folder + '*.apk').each do |apk|
			puts 'Storing file ' + apk
			puts %x[cp -v #{apk} #{folder + '/'}]
		end
	end

	def buildAll
		buildSuccessful = true
		Dir.entries(@@flavour_folder).each do |f|
			if f.index('.') != 0 # Gotta be a better way to exclude '.' and '..'
				buildSuccessful = buildSingleFlavour(f)
				if !buildSuccessful 
					return false
				end
			end
		end
		return true
	end

	def buildSingleFlavour(flavour)
		buildSingleFlavourWithConfig(BuildConfig.new(flavour, false))
	end

	def buildSingleFlavourWithConfig(config)
		puts 'Building flavour from:'
		puts @@flavour_folder + config.flavour
		if File.directory?(@@flavour_folder + config.flavour)
			result = build(config)
			@results[config.flavour] = result
			return result
		end

		puts 'Flavour does not exist: '+config.flavour
		return false
	end

	def printResults
		puts "\nBUILD RESULTS:"
		@results.each_pair{ |k,v| 
			msg = v ? 'SUCCESS' : 'FAILED'
			puts "#{k}: #{msg}"
		}
	end

end


builder = Builder.new

case ARGV.length
when 0
	success = builder.buildAll
when 1
	success = builder.buildSingleFlavour(ARGV[0])
else
	puts 'Invalid arguments.'
	success = false
end

builder.printResults