# *****************************************************************
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2019, 2020. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# *****************************************************************

export CMAKE_LIBRARY_PATH=$PREFIX/lib:$PREFIX/include:$CMAKE_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$PREFIX
export PATH=$PREFIX/bin:$PATH

# Magma's Makefile and "make.inc.openblas" allow us to override GPU_TARGET,
# OPENBLASDIR, and CUDADIR, so we do that here.
#
# But those Magma files also hard code things like build tool names and their
# associated flags. We want to replace many of those with Anaconda versions
# so we patch "make.inc.openblas" (see meta.yaml) to allow us to override,
# and then supply the overridden values here. conda populates several standard
# build variables with appropriate values, but Magma uses non-standard
# names in a few cases:
#
#    make.inc name        conda-provided variable
#    CC                   (same)
#    CXX                  (same)
#    NVCC                 --
#    FORT                 F77, F90, F95, FC, or GFORTRAN
#    ARCH                 AR
#    RANLIB               (same)
#    CFLAGS               (same)
#    FFLAGS               FFLAGS or FORTRANFLAGS
#    F90FLAGS             FFLAGS or FORTRANFLAGS (see below)
#    CXXFLAGS             (same)
#
# We ignore/omit any Fortran items because we build without Fortran
# anyway.

# General content / dependency overrides
export OPENBLASDIR="$PREFIX"
export CUDADIR="$PREFIX"
#export CUDAToolkit_INCLUDE_DIRS="$CUDA_HOME"/include

# Basic toolchain overrides
export ARCH="$AR"

cp make.inc-examples/make.inc.openblas ./make.inc

# Anaconda pre-seeds CFLAGS and CXXFLAGS with preferred settings.
# Among those for C++ is "-std=c++17". But NVIDIA's nvcc compiler 
# does not support "-std=c++17" (at least through CUDA 10). nvcc does
# support "c++14", so substitute that into CXXFLAGS as closest
# standard supported by both tool sets.
export CXXFLAGS="$(echo $CXXFLAGS | sed -e 's/ -std=[^ ]*//') -std=c++14"

mkdir build
cd build
cmake .. -DUSE_FORTRAN=OFF -DGPU_TARGET="sm_37 sm_60 sm_70 sm_75" -DCMAKE_INSTALL_PREFIX=$PREFIX
make -j$(getconf _NPROCESSORS_CONF)
make install
cd ..
