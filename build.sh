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
    echo "------------"
    ls -l ${PYBIN} || true
    echo "------------"
    ls -l ${PYBIN}/.. || true
    echo "------------"
    ls -l ${PYBIN}/../include || true
    echo "------------"
    ls -l ${PYBIN}/../lib || true
    echo "------------"
    if ! [[ ${PYBIN} =~ 35 ]] ; then
        export PYTHON_INCLUDE_DIR=${PYBIN}/../include
        export PYTHON_LIBRARY=${PYBIN}/../lib/python*/libpython*.a
        export PYTHON_EXECUTABLE=${PYBIN}/python
        "${PYBIN}/pip" wheel ./clingo/ --no-deps -w wheelhouse/
    fi
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    repair_wheel "$whl"
done

ls -l wheelhouse/
