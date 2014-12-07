################################################################################################
# OpenCV.jl
#
# The OpenCV interface (C++) for Julia
#
# If OpenCV is already installed in your computer, or you wish to use different libraries,
# change the library and header paths to your local directories, e.g.,
#      /usr/local/lib/
#      /usr/local/include/
#
# To add more libraries, make sure to add the name to "opencv_libraries" in /src/OpenCV_libs.jl
#
#################################################################################################

using Cxx

# Check Julia version before continuing (also checked later in Cxx)
(VERSION >= v"0.4-") ? nothing :
     throw(ErrorException("Julia $VERSION does not support C++ FFI"))

# Load names of OpenCV shared libraries (pre-compiled)
include(joinpath(Pkg.dir("OpenCV"), "./src/OpenCV_libs.jl"))

# Autosearch for OpenCV installations using pkg-config
(so,si,pr) = readandwrite(`pkg-config --libs opencv`)
output = readall(so)
close(so)

path = match(Regex("/usr/local/lib/"), output)
path != nothing ? println("Found a local OpenCV installation in $(path.match).") : nothing

found = false
for i in opencv_libraries
    libfinder = match(Regex("$(i[1:end-6])"), output)
    if  libfinder != nothing
        # println("$(libfinder.match) is installed")  # for debugging
        found = true
    else
        println("$(i) is not installed")
    end
end

# Choose locally pre-installed or OpenCV.jl libraries (OSX only)
if found && path != nothing
    const cvlibdir = joinpath(Pkg.dir("OpenCV"), "/usr/local/lib/")
    const cvheaderdir = joinpath(Pkg.dir("OpenCV"), "/usr/local/include/")
elseif !found
    # Load libs/headers in /deps/usr/lib/ - only for Mac OSX (dylib)
    const cvlibdir = @osx? joinpath(Pkg.dir("OpenCV"), "./deps/usr/lib/") : throw(ErrorException("No pre-installed libraries. Set path manually or install OpenCV."))
    const cvheaderdir = @osx? joinpath(Pkg.dir("OpenCV"), "./deps/usr/include/") : throw(ErrorException("No pre-installed headers. Set path manually or install OpenCV."))
end

addHeaderDir(cvlibdir; kind = C_System)

# Load OpenCV shared libraries
# IMPORTANT: if necessary, make sure to link symbols accross libraries with RTLD_GLOBAL
for i in opencv_libraries
    dlopen_e(joinpath(cvlibdir,i), RTLD_GLOBAL)==C_NULL ? throw(ArgumentError("Skip loading $(i)")): nothing
end

# Now include C++ header files
addHeaderDir(joinpath(cvheaderdir,"opencv2"), kind = C_System )
addHeaderDir(joinpath(cvheaderdir,"opencv2/core"), kind = C_System )
cxxinclude(joinpath(cvheaderdir,"opencv2/opencv.hpp"))
    # => opencv.hpp calls all the main headers
    #include "opencv2/core.hpp"
    #include "opencv2/imgproc.hpp"
    #include "opencv2/photo.hpp"
    #include "opencv2/video.hpp"
    #include "opencv2/features2d.hpp"
    #include "opencv2/objdetect.hpp"
    #include "opencv2/calib3d.hpp"
    #include "opencv2/imgcodecs.hpp"
    #include "opencv2/videoio.hpp"
    #include "opencv2/highgui.hpp"
    #include "opencv2/ml.hpp"

cxxinclude(joinpath(cvheaderdir,"opencv2/core/ocl.hpp"))  # OpenCL
cxxinclude(joinpath(cvheaderdir,"opencv2/shape.hpp"))
cxxinclude(joinpath(cvheaderdir,"opencv2/stitching.hpp"))
cxxinclude(joinpath(cvheaderdir,"opencv2/superres.hpp"))
cxxinclude(joinpath(cvheaderdir,"opencv2/videostab.hpp"))

# Include C++ headers
cxx"""
 #include <iostream>
 #include <unistd.h>
 #include <cstdlib>
 #include <cstdio>
 #include <cstddef>
 #include <cstring>
 #include <cfloat>
 #include <vector>
 #include <ctime>
 #include <map>
 #include <utility>
 #include <exception>
"""

# Load Qt framework
include(joinpath(Pkg.dir("OpenCV"), "./deps/Qt_support.jl"))

# Load header constants and typedefs
include(joinpath(Pkg.dir("OpenCV"), "./src/OpenCV_hpp.jl"))

# Load OpenCV bindings
include(joinpath(Pkg.dir("OpenCV"), "./src/OpenCV_modules.jl"))

# Load custom utility functions
include(joinpath(Pkg.dir("OpenCV"), "./src/OpenCV_util.jl"))

# Load Videoplayer
include(joinpath(Pkg.dir("OpenCV"), "./src/Videoprocessor.jl"))

# Load demos -- currently Cxx versions
function run_tests()
    include(joinpath(Pkg.dir("OpenCV"), "./test/cxx/demos.jl"))
end

