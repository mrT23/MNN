set -e

ABI="armeabi-v7a"
BUILD_DIR=build

ABI="arm64-v8a"
BUILD_DIR=build_64


OPENMP="ON"
VULKAN="OFF"
OPENCL="ON"
OPENGL="ON"
ARM82="ON"
RUN_LOOP=100
FORWARD_TYPE=0
CLEAN=""
PUSH_MODEL=""
BIN=benchmark.out

WORK_DIR=`pwd`
# BUILD_DIR=/Users/hussamlawen/work/MNN/project/android/build_64
ANDROID_NDK=/mnt/d/programms/android-ndk-r21d-linux-x86_64/android-ndk-r21d/
BENCHMARK_MODEL_DIR=C:/git/SesaMind-Train/tests/outputs/mnn/fp32
BENCHMARK_MODEL_DIR=C:/git/SesaMind-Train/outputs/comparison

BENCHMARK_FILE_NAME=benchmark.txt
ANDROID_DIR=/data/local/tmp
ADB=/mnt/d/programms/fastboot_adb/adb.exe
DEVICE_ID=QYJ7N17A10000471
#DEVICE_ID=8571c3e1
#DEVICE_ID=R9JN609F0VJ

function usage() {
    echo "-64\tBuild 64bit."
    echo "-c\tClean up build folders."
    echo "-p\tPush models to device"
}
function die() {
    echo $1
    exit 1
}

function clean_build() {
    echo $1 | grep "$BUILD_DIR\b" > /dev/null
    if [[ "$?" != "0" ]]; then
        die "Warnning: $1 seems not to be a BUILD folder."
    fi
    rm -rf $1
    mkdir $1
}

function build_android_bench() {
    if [ "-c" == "$CLEAN" ]; then
        clean_build $BUILD_DIR
    fi
    if [ "$ABI" != "arm64-v8a" ]; then
      mkdir -p build
    else
      mkdir -p build_64
    fi
    cd $BUILD_DIR
    # cmake ../../ \
          # -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
          # -DCMAKE_BUILD_TYPE=Release \
          # -DANDROID_ABI="${ABI}" \
          # -DANDROID_STL=c++_static \
          # -DCMAKE_BUILD_TYPE=Release \
          # -DANDROID_NATIVE_API_LEVEL=android-21  \
          # -DANDROID_TOOLCHAIN=clang \
          # -DMNN_VULKAN:BOOL=$VULKAN \
          # -DMNN_OPENCL:BOOL=$OPENCL \
          # -DMNN_OPENMP:BOOL=$OPENMP \
          # -DMNN_OPENGL:BOOL=$OPENGL \
		  # -DMNN_ARM82:BOOL=$ARM82 \
          # -DMNN_USE_THREAD_POOL=OFF \
          # -DMNN_DEBUG:BOOL=OFF \
          # -DMNN_BUILD_BENCHMARK:BOOL=ON \
          # -DMNN_BUILD_FOR_ANDROID_COMMAND=true \
          # -DNATIVE_LIBRARY_OUTPUT=.
    # make -j8 benchmark.out timeProfile.out
}

function bench_android() {

    echo $ABI
    build_android_bench
    pwd
    for file in *.so; do
        echo $file
        $ADB -s $DEVICE_ID push $file  $ANDROID_DIR
    done

    $ADB -s $DEVICE_ID push benchmark.out $ANDROID_DIR
    $ADB -s $DEVICE_ID push timeProfile.out $ANDROID_DIR
    $ADB -s $DEVICE_ID shell chmod 0777 $ANDROID_DIR/benchmark.out

    if [ "" != "$PUSH_MODEL" ]; then
        $ADB -s $DEVICE_ID shell "rm -rf $ANDROID_DIR/benchmark_models"
        $ADB -s $DEVICE_ID push $BENCHMARK_MODEL_DIR $ANDROID_DIR/benchmark_models
    fi
    if [ "$BIN" != "create_lut.out" ]; then
      echo $BENCHMARK_FILE_NAME
      $ADB -s $DEVICE_ID shell "rm -f $ANDROID_DIR/$BENCHMARK_FILE_NAME"
      $ADB -s $DEVICE_ID shell "echo >> $ANDROID_DIR/$BENCHMARK_FILE_NAME"
      $ADB -s $DEVICE_ID shell "echo Build Flags: ABI=$ABI  OpenMP=$OPENMP Vulkan=$VULKAN OpenCL=$OPENCL >> $ANDROID_DIR/$BENCHMARK_FILE_NAME"

      #benchmark  CPU 4 threds
	  echo "OpenCL"
      $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 3 1 2 0 >$ANDROID_DIR/benchmark.err >> $ANDROID_DIR/$BENCHMARK_FILE_NAME"
      $ADB -s $DEVICE_ID pull $ANDROID_DIR/$BENCHMARK_FILE_NAME
	  echo "done"
	  sleep 10
      #echo "CPU 4 threads"
      #$ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 $FORWARD_TYPE 4 2 1 >$ANDROID_DIR/benchmark.err >> $ANDROID_DIR/$BENCHMARK_FILE_NAME"
      #sleep 10
      echo "CPU 1 threads"
      $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 $FORWARD_TYPE 1 2 1 >$ANDROID_DIR/benchmark.err >> $ANDROID_DIR/$BENCHMARK_FILE_NAME"
      # echo "Vulkan"
      #benchmark  Vulkan
      # $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 7 4 2> $ANDROID_DIR/benchmark.err >> $ANDROID_DIR/$BENCHMARK_FILE_NAME"
      #benchmark OpenGL
      # $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 6 4 2 >$ANDROID_DIR/benchmark.err >> $ANDROID_DIR/$BENCHMARK_FILE_NAME"
#      benchmark OpenCL

      $ADB -s $DEVICE_ID pull $ANDROID_DIR/$BENCHMARK_FILE_NAME
    else
      LUT_FOLDER="$ANDROID_DIR/${BENCHMARK_FILE_NAME}_${soc_code}_lut"
      $ADB -s $DEVICE_ID shell "rm -rf $LUT_FOLDER"
      $ADB -s $DEVICE_ID shell "mkdir $LUT_FOLDER"
      for i in `seq 160 16 224`;
        do
          echo $i
          BENCHMARK_FILE_NAME="${i}_lookup_table.yaml"
          $ADB -s $DEVICE_ID shell "echo >> $LUT_FOLDER/$BENCHMARK_FILE_NAME"

          #benchmark  CPU
          $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models/$i $RUN_LOOP 10 $FORWARD_TYPE 4 2 $i >$ANDROID_DIR/benchmark.err >> $LUT_FOLDER/$BENCHMARK_FILE_NAME"

          #benchmark  Vulkan
          # $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 7 4 2 $i >$LUT_FOLDER/lut.err >> $LUT_FOLDER/$BENCHMARK_FILE_NAME"
          #benchmark OpenGL
          # $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 6 4 2 $i >$LUT_FOLDER/lut.err >> $LUT_FOLDER/$BENCHMARK_FILE_NAME"
          #benchmark OpenCL
          # $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 3 4 2 $i >$LUT_FOLDER/lut.err >> $LUT_FOLDER/$BENCHMARK_FILE_NAME"
          #benchmark Auto
          # $ADB -s $DEVICE_ID shell "LD_LIBRARY_PATH=$ANDROID_DIR $ANDROID_DIR/$BIN $ANDROID_DIR/benchmark_models $RUN_LOOP 10 4 4 2 $i >$LUT_FOLDER/lut.err >> $LUT_FOLDER/$BENCHMARK_FILE_NAME"

          $ADB -s $DEVICE_ID pull $LUT_FOLDER ../
        done
    fi



}
# PUSH_MODEL="-p"
while [ "$1" != "" ]; do
    case $1 in
        -64)
            shift
            ABI="arm64-v8a"
            # BUILD_DIR=/Users/hussamlawen/work/MNN/project/android/build_64
            BUILD_DIR=build_64
            ;;
        -c)
            shift
            CLEAN="-c"
            ;;
        -p)
            shift
            PUSH_MODEL="-p"
            ;;
        -d)
            shift
            echo $1
            DEVICE_ID=$1
            shift
            ;;
        -lut)
            shift

            # BENCHMARK_MODEL_DIR=/Users/hussamlawen/work/ofa_lut/lut2/lut_mnn
            # BENCHMARK_MODEL_DIR=/Users/hussamlawen/work/multi_res_luts/mnn
            BENCHMARK_MODEL_DIR=$BENCHMARK_MODEL_DIR
            # BENCHMARK_MODEL_DIR=/Users/hussamlawen/work/ofa_lut/lut2/oneplus8_lut_extra
            ;;
        *)
            # echo $1
            usage
            exit 1
    esac
done

bench_android
