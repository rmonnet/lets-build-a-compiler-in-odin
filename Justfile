compiler := "./crc" + (if os() == "windows" { ".exe" } else { "" })

# List all the recipes.'
_list-recipes:
    @just --list

# Count the SLOCs in the project
@slocs:
    echo ""; echo "Compiler"
    tokei compiler
    echo ""; echo "Pascal Library"
    tokei pascal
    echo ""; echo "Interpreter"
    tokei interpreter

# Build the compiler
@build:
    rm -f {{ compiler }}
    odin build compiler -out:{{ compiler }} -debug
    echo "type " {{ compiler }} "to run the Crenshaw compiler."

# Run all the tests in the project
test:
    -odin test compiler -vet -debug -disallow-do -define:ODIN_TEST_SHORT_LOGS=true -define:ODIN_TEST_LOG_LEVEL=warning
    -odin test interpreter -vet -debug -disallow-do -define:ODIN_TEST_SHORT_LOGS=true -define:ODIN_TEST_LOG_LEVEL=warning

# Provides system information
@system-info:
    version=$(odin version); echo "Version  :${version#*version}"
    echo "CPU Arch : {{ arch() }}"
    echo "# cores  : {{ num_cpus() }}"
    echo "OS       : {{ os() }}"

# Clean up the project
@clean:
    rm -rf *.exe
    rm -rf *.pdb

# Vet the code in the project
@vet:
    -odin check pascal -vet
    -odin check compiler -vet
