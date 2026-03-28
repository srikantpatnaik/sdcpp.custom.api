mkdir -p build && cd build
cmake .. -DSD_CUDA=ON
cmake --build . --config Release -j12
cd ..
