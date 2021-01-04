#!/bin/bash
set -e -u -x

version=17

function repair_wheel {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" --plat "$PLAT" -w wheelhouse/
        rm -f "$wheel"
    fi
}

# Temporary, for testing purposes only
function rename_wheel {
    interp="$1"
    wheel="$2"
    $interp -m wheel unpack --dest rename_wheel "$wheel"
    rm "$wheel"
    sed -i 's/Name: clingo-cffi/Name: clingo-cffi-wheel/g' rename_wheel/clingo_cffi*/clingo_cffi*/METADATA
    $interp -m wheel pack rename_wheel/clingo_cffi*
    mv "$(basename $wheel)" "$(echo $wheel | sed 's/clingo_cffi/clingo_cffi_wheel/g')"
    rm -rf rename_wheel
}

# Apply build system patches
cd clingo && git apply ../dynamic_lookup.patch && cd ..

# Bump the version number
sed -i "s/post16/post$version/g" clingo/setup.py

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    # Requires Py3.6 or greater - on the docker image 3.5 is cp35-cp35m
    if ! [[ ${PYBIN} =~ 35 ]] ; then
        "${PYBIN}/pip" wheel ./clingo/ --no-deps -w wheelhouse/
        just_built_wheel=$(ls -Art wheelhouse/ | tail -n 1)
        rename_wheel "${PYBIN}/python" "wheelhouse/$just_built_wheel"
    fi
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    repair_wheel "$whl"
done

ls -l wheelhouse/
