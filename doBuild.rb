#%x[git rev-parse --show-toplevel]
TOP_LEVEL = Dir.pwd 
PROJECT_DIRECTORY =  TOP_LEVEL + '/project/'
RES_FOLDER = PROJECT_DIRECTORY + 'res/'
BIN_FOLDER = PROJECT_DIRECTORY + 'bin/'
FLAVOUR_FOLDER = TOP_LEVEL + '/flavours/'
OUTPUT_FOLDER = TOP_LEVEL + '/builds/'


def copyResources(flavour)
	path = FLAVOUR_FOLDER + flavour + '/'

	#puts 'Copying resources for ' + flavour
	#puts %x[cp -r #{path + 'res/*'} #{RES_FOLDER}]

	#puts 'Copying local.properties for ' + flavour
	#puts %x[cp #{path + 'local.properties'} #{PROJECT_DIRECTORY}]

	puts 'Copying resources for ' + flavour
	puts %x[cp -r #{path} #{PROJECT_DIRECTORY}]
end

def build(sign)
	Dir.chdir PROJECT_DIRECTORY do
		pipe = IO.popen('ant clean debug')
		while (line = pipe.gets)
			print line
		end
		pipe.close
	end

	if $?.exitstatus != 0
		return false
	end

	if sign
		pipe = IO.popen(TOP_LEVEL + '/signProjectAPK.sh')
		while (line = pipe.gets)
			print line
		end
		pipe.close
	end

	return $?.exitstatus == 0
end

def storeArtifacts(flavour)
	folder = OUTPUT_FOLDER + flavour
	puts %x[mkdir #{folder}]
	Dir.glob(BIN_FOLDER + '*.apk').each do |apk|
		puts 'Storing file ' + apk
		puts %x[cp -v #{apk} #{folder + '/'}]
	end
end


def buildAll()
	buildSuccessful = true
	Dir.entries(FLAVOUR_FOLDER).each do |f|
		if f.index('.') != 0 # Gotta be a better way to exclude '.' and '..'
			buildSuccessful = buildSingleFlavour(f)
			if buildSuccessful 
				storeArtifacts(f)
			else
				return false
			end
		end
	end
	return true
end

def buildSingleFlavour(flavour)
	if File.directory?(FLAVOUR_FOLDER + flavour)
		copyResources(flavour)
		return build(false)
	end

	puts 'Flavour does not exist: '+flavour
	return false
end


case ARGV.length
when 0
	success = buildAll
when 1
	success = buildSingleFlavour(ARGV[0])
else
	puts '...what?'
	success = false
end

if success
	puts 'Build successful'
else
	puts 'Build failed'
end