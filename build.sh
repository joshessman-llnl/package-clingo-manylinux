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
        export Python_INCLUDE_DIR=${PYBIN}/../include/python*
        export Python_LIBRARY=${PYBIN}/../lib/python*/libpython*.so
        export Python_EXECUTABLE=${PYBIN}/python
        echo $Python_INCLUDE_DIR
        file $Python_INCLUDE_DIR
        echo $Python_LIBRARY
        file $Python_LIBRARY
        echo $Python_EXECUTABLE
        file $Python_EXECUTABLE
        "${PYBIN}/pip" wheel ./clingo/ --no-deps -w wheelhouse/
    fi
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    repair_wheel "$whl"
done

ls -l wheelhouse/
