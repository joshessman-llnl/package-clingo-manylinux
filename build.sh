#!/bin/bash
set -e -u -x

version=20

function repair_wheel {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" --plat "$PLAT" -w wheelhouse/
        rm -f "$wheel"
    fi
}

# Install re2c
arch=$(uname -m)
if [[ "$arch" == "ppc64le" ]]; then
    mkdir re2c_build
    pushd re2c_build
    # Build from source
    curl -LJO https://github.com/skvadrik/re2c/archive/2.0.3.tar.gz
    tar xzf re2c*
    cd re2c* && mkdir .build && cd .build && cmake .. -DRE2C_BUILD_RE2GO=OFF && cmake --build . -j4 && cmake --install .
    popd
else
    yum install -y re2c bison
fi

# Apply build system patches
cd clingo && git apply ../dynamic_lookup.patch && cd ..

# Bump the version number
sed -i "s/post16/post$version/g" clingo/setup.py

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    # Requires Py3.6 or greater - on the docker image 3.5 is cp35-cp35m
    if ! [[ ${PYBIN} =~ 35 ]] ; then
        "${PYBIN}/pip" wheel ./clingo/ --no-deps -w wheelhouse/
    fi
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    repair_wheel "$whl"
done

ls -l wheelhouse/
