#!/bin/ksh -x

brew=`which brew`;
prefix=`dirname $brew`;
org="homebrew";
tap="core";

# Hardcoded list of exceptions (libraries provided by glibc or an explicit system dependency)
exceptions=( ld-linux-x86-64.so.2 libc.so.6 libm.so.6 ); 

function link-available()
{
    executable=$0;
    formula=$1;
    linked=( `patchelf --print-needed $executable` );
    deps=( `$brew deps $formula` );
    # Temporary crude test - see if the binary links to a library named "*$dep*"
    for link in linked
    do
        for dep in deps
        do
            case $dep in
                *$link*) return 0
        done
    done
    return 1
}            

for formulafile in `dir $prefix/Library/Taps/$org/homebrew-$tap`
do
    formula=`basename $formulafile .rb`;
    $brew install -v $formula;
    if [ $? -ne 0 ]
    then
        echo "Installing $formula failed! Skipping."
        continue;
    fi
    executables=`dir $prefix/opt/$formula/bin`;
    for $executable in $executables
    do
        link-available $executable $formula;
        if [ $? -ne 0 ]
        then
            echo "$formula is missing a dependency!";
        fi
    done
done
