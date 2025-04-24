#!/bin/bash

#
# This script will build OpenSceneGraph (OSG) libraries
# needed for esmini to visualize the road network and scenario.
# No system installations will be done (no admin rights required)
#
# While the ambition is to support Windows, Linux and Mac the script is under
# development and has not been tested thoroughly on all three platforms. But
# hopefully it can at least provide some guidance and ideas.
#
# Prerequisites:
# - Git (with Bash) (https://git-scm.com/download/win)
# - cmake (https://cmake.org/download/)
# - compiler (Visual Studio with C++ toolkit, gcc, xcode...)
#
# Usage:
# - put this script in an empty folder
# - open bash (e.g. Git Bash) in that folder
# - review and adjust system dependent parameters in section below
# - run the script: ./generate_osi_libs.sh
# - wait (the build process will take approx. 15 minutes depending on...)
#
# The osi_*.7z will contain both headers and needed libraries. (* depends on platform)
#
# 7-zip uncompress tool:
#   Ubuntu: sudo apt-get install p7zip-full
#   Windows: https://www.7-zip.org/download.html
#

# -----------------------------------------------------------------------------------
# Review and update settings in this section according to your system and preferences

OSG_REPO=https://github.com/esmini/OpenSceneGraph_for_esmini
# Specify version as branch or tag, e.g. OpenSceneGraph_for_esmini or OpenSceneGraph-3.6.5.
OSG_VERSION=OpenSceneGraph-3.6.5
fbx_support=false  # users are encouraged to convert fbx to osgb format whenever possible
# Parallel compile. Set specific number, e.g. "-j4" or empty "-j" for compiler default. Set to "" for cmake versions < 3.12.
PARALLEL_BUILDS="-j4"
ZIP_MIN_VERSION=12

if [ "$OSTYPE" == "msys" ]; then
    # comment out line below to use default generator
    GENERATOR_ARGUMENTS=(-G "Visual Studio 17 2022" -T v142 -A x64)

    # Make sure 7zip is available, else download and install it
    # https://www.7-zip.org/download.html

    LIB_EXT="lib"
    LIB_PREFIX=""
    LIB_OSG_PREFIX="osg*-"
    LIB_OT_PREFIX="ot*-"

    target_dir="v10"
    zfilename="osg_v10.7z"
    z_exe="$PROGRAMFILES/7-Zip/7z"

elif [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
    LIB_EXT="a"
    LIB_PREFIX="lib"
    LIB_OSG_PREFIX="lib"
    LIB_OT_PREFIX="lib"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        target_dir="linux"
        zfilename="osg_linux.7z"
        z_exe=7za
    else
        target_dir="mac"
        zfilename="osg_mac.7z"
        z_exe=7z
        macos_arch="arm64;x86_64"
    fi
else
    echo Unknown OSTYPE: $OSTYPE
fi

# ---------------------------------------------------------------------------------------
# From this point no adjustments should be necessary, except fixing bugs in the script :)
# However you might want to adjust versions of software packages being checkout and built

osg_root_dir=$(pwd)

echo ------------------------ Installing dependencies ------------------------------------

cd $osg_root_dir
if [ "$OSTYPE" == "msys" ]; then
    if [ ! -d 3rdParty_x64 ]; then
        if [ ! -f 3rdParty_VS2017_v141_x64_V11_full.7z  ]; then
            curl -L "https://www.dropbox.com/scl/fi/fs54s1g2zbjbi6ou7zjt0/3rdParty_VS2017_v141_x64_V11_full.7z?rlkey=usiax6ry5xvclmye7sdypqwd9&st=fhfauw9e&dl=1" -O
            "$z_exe" x 3rdParty_VS2017_v141_x64_V11_full.7z
        fi
    fi

    if [ $fbx_support = true ]; then
        if [ ! -f fbx202021_fbxsdk_vs2017_win.exe ]; then
            curl --user-agent  "Mozilla/5.0" -L https://www.autodesk.com/content/dam/autodesk/www/adn/fbx/2020-2-1/fbx202021_fbxsdk_vs2017_win.exe -o fbx202021_fbxsdk_vs2017_win.exe
        fi

        if [ ! -d "$PROGRAMFILES/Autodesk/FBX/FBX SDK/2020.2.1/include" ]; then
            echo Installing FBX SDK...
            powershell -Command "Start-Process fbx202021_fbxsdk_vs2017_win.exe -ArgumentList /S -Wait"
        else
            echo FBX SDK already installed
        fi

        fbx_include="$PROGRAMFILES/Autodesk/FBX/FBX SDK/2020.2.1/include"
        fbx_lib_release="$PROGRAMFILES/Autodesk/FBX/FBX SDK/2020.2.1/lib/vs2017/x64/release/libfbxsdk-md.lib"
        fbx_lib_debug="$PROGRAMFILES/Autodesk/FBX/FBX SDK/2020.2.1/lib/vs2017/x64/debug/libfbxsdk-md.lib"
        fbx_xml_lib="$PROGRAMFILES/Autodesk/FBX/FBX SDK/2020.2.1/lib/vs2017/x64/release/libxml2-md.lib"
        fbx_xml_lib_debug="$PROGRAMFILES/Autodesk/FBX/FBX SDK/2020.2.1/lib/vs2017/x64/debug/libxml2-md.lib"
        fbx_zlib_lib="$PROGRAMFILES/Autodesk/FBX/FBX SDK/2020.2.1/lib/vs2017/x64/release/zlib-md.lib"
        fbx_zlib_lib_debug="$PROGRAMFILES/Autodesk/FBX/FBX SDK/2020.2.1/lib/vs2017/x64/debug/zlib-md.lib"
    fi

elif  [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then

    if [ ! -d zlib ]; then
        git clone https://github.com/madler/zlib.git --depth 1 --branch v1.2.$ZIP_MIN_VERSION
        cd  zlib
        mkdir install
        mkdir build
        cd build

        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            cmake "${GENERATOR_ARGUMENTS[@]}" -D CMAKE_INSTALL_PREFIX=../install -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_FLAGS="-fPIC" ..
            cmake --build . $PARALLEL_BUILDS --target install
            mv ../install/lib/libz.a ../install/lib/libzd.a

            rm CMakeCache.txt
            cmake "${GENERATOR_ARGUMENTS[@]}" -D CMAKE_INSTALL_PREFIX=../install -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fPIC" ..
            cmake --build . $PARALLEL_BUILDS --target install
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            cmake "${GENERATOR_ARGUMENTS[@]}" -D CMAKE_INSTALL_PREFIX=../install -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_OSX_ARCHITECTURES="$macos_arch" ..
            cmake --build . $PARALLEL_BUILDS --target install
        else
            cmake "${GENERATOR_ARGUMENTS[@]}" -D CMAKE_INSTALL_PREFIX=../install ..
            cmake --build . $PARALLEL_BUILDS --config Debug --target install
            cmake --build . $PARALLEL_BUILDS --config Release --target install --clean-first
        fi

    else
        echo zlib folder already exists, continue with next step...
    fi

    if [ $fbx_support = true ]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [ ! -f fbx202001_fbxsdk_linux.tar.gz ]; then
                curl --user-agent  "Mozilla/5.0" -L "https://www.autodesk.com/content/dam/autodesk/www/adn/fbx/2020-0-1/fbx202001_fbxsdk_linux.tar.gz" -o fbx202001_fbxsdk_linux.tar.gz
                mkdir fbxsdk
            fi
            tar xzvf fbx202001_fbxsdk_linux.tar.gz --directory fbxsdk
            ./fbxsdk/fbx202001_fbxsdk_linux ./fbxsdk
            fbx_include="../../fbxsdk/include"
            fbx_lib_release="../../fbxsdk/lib/gcc/x64/release/libfbxsdk.a"
            fbx_lib_debug="../../fbxsdk/lib/gcc/x64/debug/libfbxsdk.a"
            fbx_xml_lib=libxml2.so
            fbx_zlib_lib=libz.so
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            curl --user-agent  "Mozilla/5.0" -L "https://www.autodesk.com/content/dam/autodesk/www/adn/fbx/2020-2-1/fbx202021_fbxsdk_clang_mac.pkg.tgz" -o fbx202021_fbxsdk_clang_mac.pkg.tgz
            tar xzvf fbx202021_fbxsdk_clang_mac.pkg.tgz
            sudo installer -pkg fbx202021_fbxsdk_clang_macos.pkg -target /
            fbx_include="/Applications/Autodesk/FBX SDK/2020.2.1/include"
            fbx_lib_release="/Applications/Autodesk/FBX SDK/2020.2.1/lib/clang/release/libfbxsdk.a"
            fbx_lib_debug="/Applications/Autodesk/FBX SDK/2020.2.1/lib/clang/debug/libfbxsdk.a"
            fbx_xml_lib=libxml2.dylib
            fbx_zlib_lib=libz.dylib
        fi
    fi
fi

cd $osg_root_dir
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    if [ ! -d jpeg-9e ]; then
        if [ ! -f jpegsrc.v9e.tar.gz ]; then
            curl -L -O http://www.ijg.org/files/jpegsrc.v9e.tar.gz
        fi
        tar xzf jpegsrc.v9e.tar.gz
        cd jpeg-9e
        if [[ "$OSTYPE" == "darwin"* ]]; then
            ./configure CFLAGS="-arch arm64 -arch x86_64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -mmacosx-version-min=10.15"
            make
        else
            ./configure CFLAGS='-fPIC -g'; make $PARALLEL_BUILDS
            mv .libs .libsd
            mv .libsd/libjpeg.a .libsd/libjpegd.a
            make clean
            ./configure CFLAGS='-fPIC'; make $PARALLEL_BUILDS
        fi
    else
        echo jpeg folder already exists, continue with next step...
    fi
fi

echo ------------------------ Installing OSG ------------------------------------

cd $osg_root_dir
if [ ! -d OpenSceneGraph ]; then
    # use fork including some fixes
    git clone $OSG_REPO --branch $OSG_VERSION OpenSceneGraph

    cd OpenSceneGraph
    git describe --long --dirty

    # Apply fix for comment format not accepted by all platforms
    git checkout 63bb537132bab1f8b077838f7550e26405e5fa35 CMakeModules/FindFontconfig.cmake

    # Apply fix for Mac window handler
    git checkout 3994378a20948ebc4ed10b7cd33a6cc5393e7157 src/osgViewer/GraphicsWindowCocoa.mm

    # Apply fix '_FPOSOFF' has been deprecated #26231
    git checkout fca3b5b9a9f1c36ddf08ed08cbe02a2668fa4ee9 src/osgPlugins/osga/OSGA_Archive.cpp

    # Enforce pthread sched_yield() in favor of pthread_yield() which was deprecated in glibc 2.34
    sed -i 's/CHECK_FUNCTION_EXISTS(pthread_yield/# CHECK_FUNCTION_EXISTS(pthread_yield/g' src/OpenThreads/pthreads/CMakeLists.txt

    # unstage and show status of the repo
    git reset
    git describe --long --dirty
fi

cd $osg_root_dir
if [ ! -d OpenSceneGraph/build ]; then
    cd OpenSceneGraph
    mkdir build
    cd build

    COMMON_ARGS="-DOSG_AGGRESSIVE_WARNINGS=False -DDYNAMIC_OPENSCENEGRAPH=false -DDYNAMIC_OPENTHREADS=false -DBUILD_OSG_APPLICATIONS=False -DBUILD_OSG_EXAMPLES=False -DBUILD_OSG_DEPRECATED_SERIALIZERS=False -DFBX_INCLUDE_DIR="$fbx_include" "
    echo $COMMON_ARGS

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        COMMON_ARGS2="-DOPENGL_PROFILE=GL2 -DCMAKE_CXX_FLAGS=-fPIC -DJPEG_INCLUDE_DIR=$osg_root_dir/jpeg-9e "

        cmake ${COMMON_ARGS} ${COMMON_ARGS2} -DJPEG_LIBRARY=$osg_root_dir/jpeg-9e/.libs/libjpeg.a -DFBX_LIBRARY="$fbx_lib_release" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../install ..
        cmake --build . $PARALLEL_BUILDS --target install

        # build debug variant
        rm CMakeCache.txt
        cmake ${COMMON_ARGS} ${COMMON_ARGS2} -DJPEG_LIBRARY=$osg_root_dir/jpeg-9e/.libsd/libjpegd.a -DFBX_LIBRARY="$fbx_lib_debug" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install-debug ..
        cmake --build . $PARALLEL_BUILDS --target install

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        cmake ${COMMON_ARGS} -DOSG_TEXT_USE_FONTCONFIG=false -DOPENGL_PROFILE=GL2 -DJPEG_INCLUDE_DIR=$osg_root_dir/jpeg-9e -DJPEG_LIBRARY_RELEASE=$osg_root_dir/jpeg-9e/.libs/libjpeg.a -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS -fPIC -DGL_SILENCE_DEPRECATION" -DCMAKE_OSX_ARCHITECTURES="$macos_arch" -DCMAKE_INSTALL_PREFIX=../install ..

        cmake --build . -j $PARALLEL_BUILDS --config Release --target install

    elif [ "$OSTYPE" == "msys" ]; then
        COMMON_ARGS2="-DOPENGL_PROFILE=GL3 -DACTUAL_3RDPARTY_DIR=../../3rdParty_x64/x64 -DFBX_INCLUDE_DIR="$fbx_include" -DFBX_LIBRARY="$fbx_lib_release" -DFBX_LIBRARY_DEBUG="$fbx_lib_debug" "

        cmake "${GENERATOR_ARGUMENTS[@]}" ${COMMON_ARGS} ${COMMON_ARGS2} -DCMAKE_INSTALL_PREFIX=../install -DFBX_XML2_LIBRARY="$fbx_xml_lib_release" -DFBX_ZLIB_LIBRARY="$fbx_zlib_lib_release" ..
        cmake --build . -j $PARALLEL_BUILDS --config Release --target install

        # build debug variant
        rm CMakeCache.txt

        cmake "${GENERATOR_ARGUMENTS[@]}" ${COMMON_ARGS} ${COMMON_ARGS2} -DCMAKE_INSTALL_PREFIX=../install-debug -DFBX_XML2_LIBRARY="$fbx_xml_lib_debug" -DFBX_ZLIB_LIBRARY="$fbx_zlib_lib_debug" ..
        cmake --build . -j $PARALLEL_BUILDS --config Debug --target install
    else
        echo Unknown OSTYPE: $OSTYPE
    fi
fi

echo ------------------------ Pack ------------------------------------

cd $osg_root_dir

plugins_dir=$(find OpenSceneGraph/install/lib -maxdepth 1 -type d -name "osgPlugins-*")
if [ -d "$plugins_dir" ]; then
    plugins_dir_name=$(basename $plugins_dir)
else
    echo "Plugins folder not found. Exiting..."
    exit 1
fi

if [ ! -d $target_dir ]; then
    mkdir $target_dir
    mkdir $target_dir/include
    mkdir $target_dir/lib
    mkdir $target_dir/lib/$plugins_dir_name
fi
cp -r OpenSceneGraph/install/include $target_dir/

if [ "$OSTYPE" == "msys" ]; then
    cp 3rdParty_x64/x64/include/zlib.h $target_dir/include
    cp 3rdParty_x64/x64/lib/zlibstatic.lib 3rdParty_x64/x64/lib/zlibstaticd.lib $target_dir/lib
    cp 3rdParty_x64/x64/include/jpeglib.h $target_dir/include
    cp 3rdParty_x64/x64/lib/jpeg.lib 3rdParty_x64/x64/lib/jpegd.lib $target_dir/lib
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    cp zlib/install/include/zlib.h $target_dir/include
    cp zlib/install/lib/libz.${LIB_EXT} zlib/install/lib/libzd.${LIB_EXT} $target_dir/lib
    cp jpeg-9e/jpeglib.h $target_dir/include
    cp jpeg-9e/.libs/libjpeg.${LIB_EXT} jpeg-9e/.libsd/libjpegd.${LIB_EXT} $target_dir/lib
else
    echo Unknown OSTYPE: $OSTYPE
fi

cd $osg_root_dir/OpenSceneGraph/install/lib
cp ${LIB_OSG_PREFIX}osg.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OSG_PREFIX}osgAnimation.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OSG_PREFIX}osgDB.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OSG_PREFIX}osgGA.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OSG_PREFIX}osgShadow.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OSG_PREFIX}osgSim.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OSG_PREFIX}osgText.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OSG_PREFIX}osgUtil.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OSG_PREFIX}osgViewer.${LIB_EXT} $osg_root_dir/$target_dir/lib
cp ${LIB_OT_PREFIX}OpenThreads.${LIB_EXT} $osg_root_dir/$target_dir/lib

cd $osg_root_dir/OpenSceneGraph/install/lib/$plugins_dir_name
cp ${LIB_PREFIX}osgdb_jpeg.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
cp ${LIB_PREFIX}osgdb_osg.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
cp ${LIB_PREFIX}osgdb_serializers_osg.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
cp ${LIB_PREFIX}osgdb_serializers_osgsim.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name

if [ $fbx_support = true ]; then
    cp ${LIB_PREFIX}osgdb_fbx.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
fi

if [[ ! "$OSTYPE" == "darwin"* ]]; then
    cd $osg_root_dir/OpenSceneGraph/install-debug/lib
    cp ${LIB_OSG_PREFIX}osgd.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OSG_PREFIX}osgAnimationd.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OSG_PREFIX}osgDBd.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OSG_PREFIX}osgGAd.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OSG_PREFIX}osgShadowd.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OSG_PREFIX}osgSimd.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OSG_PREFIX}osgTextd.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OSG_PREFIX}osgUtild.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OSG_PREFIX}osgViewerd.${LIB_EXT} $osg_root_dir/$target_dir/lib
    cp ${LIB_OT_PREFIX}OpenThreadsd.${LIB_EXT} $osg_root_dir/$target_dir/lib

    cd $osg_root_dir/OpenSceneGraph/install-debug/lib/$plugins_dir_name
    cp ${LIB_PREFIX}osgdb_jpegd.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
    cp ${LIB_PREFIX}osgdb_osgd.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
    cp ${LIB_PREFIX}osgdb_serializers_osgd.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
    cp ${LIB_PREFIX}osgdb_serializers_osgsimd.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
    if [ $fbx_support = true ]; then
        cp ${LIB_PREFIX}osgdb_fbxd.${LIB_EXT} $osg_root_dir/$target_dir/lib/$plugins_dir_name
    fi
fi

cd $osg_root_dir

"$z_exe" a -r $zfilename -m0=LZMA -bb1 -spf $target_dir/*
# unpack with: 7z x <filename>

echo ------------------------ Done ------------------------------------
