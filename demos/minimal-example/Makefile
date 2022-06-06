# NOTE: Requires julia==1.3.1, R-flowMeans

init:
	@echo "Please ensure you have installed Julia v1.3. This may not work with any other Julia version."
	julia -e 'ENV["R_HOME"] = "*"; import Pkg; Pkg.activate("."); Pkg.add(Pkg.PackageSpec(url="https://github.com/luiarthur/CytofResearch")); Pkg.build()'

