
OSX_LD_FLAGS="-framework AppKit 
              -framework Metal
              -framework MetalKit
              -framework QuartzCore"

COMMON_COMPILER_FLAGS="$OSX_LD_FLAGS"

MAC_PLATFORM_LAYER_PATH="../../code/mac_platform_layer"

BUNDLE_RESOURCES_PATH="PixelShaderDemo.app/Contents/Resources"

RESOURCES_PATH="../../resources"

PLATFORM_RESOURCES_PATH="../../code/mac_platform_layer/resources"

echo Building Mac OS Pixel Art Shader Demo
pushd ../../build/mac_os

xcrun -sdk macosx metal -mmacosx-version-min=10.14 -gline-tables-only -MO -g -c "${MAC_PLATFORM_LAYER_PATH}/PixelArtShader.metal" -o PixelArtShader.air
xcrun -sdk macosx metallib PixelArtShader.air -o PixelArtShader.metallib

echo Compiling Mac OS Pixel Art Shader Demo
clang -g -lstdc++ ${COMMON_COMPILER_FLAGS} -mmacosx-version-min=10.14 -o PixelShaderDemo "${MAC_PLATFORM_LAYER_PATH}/mac_os_main.mm"

echo Building Application Bundle
rm -rf PixelShaderDemo.app
mkdir -p $BUNDLE_RESOURCES_PATH
cp PixelShaderDemo PixelShaderDemo.app/PixelShaderDemo
cp -r PixelShaderDemo.dSYM ${BUNDLE_RESOURCES_PATH}/PixelShaderDemo.dSYM
cp -r ${RESOURCES_PATH} ${BUNDLE_RESOURCES_PATH}
cp ${PLATFORM_RESOURCES_PATH}/Info.plist PixelShaderDemo.app/Contents/Info.plist
cp PixelArtShader.metallib ${BUNDLE_RESOURCES_PATH}/PixelArtShader.metallib

popd
