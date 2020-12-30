#!/bin/bash
set -e -u -x

function repair_wheel {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" --plat "$PLAT" -w wheelhouse/
    fi
}

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    # Requires Py3.6 or greater - on the docker image 3.5 is cp35-cp35m
    if ! [[ ${PYBIN} =~ 35 ]] ; then
        export Python_ROOT_DIR=${PYBIN}/..
        cp clingo/setup.py setup.py.old
        sed -i "/CLINGO_REQUIRE_PYTHON=ON',/a \                 '-DPython_ROOT_DIR=${Python_ROOT_DIR}'," clingo/setup.py
        sed -i "/CLINGO_REQUIRE_PYTHON=ON',/a \                 '-DPYTHON_EXECUTABLE=${PYBIN}/python'," clingo/setup.py
        sed -i "/CLINGO_REQUIRE_PYTHON=ON',/a \                 '-DPYTHON_INCLUDE_DIR=${PYBIN}/../include/python*'," clingo/setup.py
        "${PYBIN}/pip" wheel ./clingo/ --no-deps -w wheelhouse/
        rm clingo/setup.py
        mv setup.py.old clingo/setup.py
    fi
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    repair_wheel "$whl"
done

ls -l wheelhouse/
