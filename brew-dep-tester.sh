#!/bin/zsh -x

# Hardcoded list of exceptions (libraries provided by glibc or an explicit system dependency)
exceptions=( "ld-linux-x86-64.so.2" "libc.so.6" "libm.so.6" );

function lib-available()
{
    formula=$1;
    lib=$2;
    deps=( `$brew deps $formula` );
    for exception in $exceptions
    do
        if [ "x$exception" = "x$link" ]
        then
            return 0;
        fi
    done
    for dep in $deps
    do
        shortdep=`basename $dep`;
        
        # Temporary crude test - see if the binary links to a library named "*$dep*"
        case $lib in
            *$shortdep*) return 0
        esac
    done
    return 1;
}

function link-available()
{
    executable=$1;
    formula=$2;
    linked=( `patchelf --print-needed $execdir/$executable` );
    
    for link in $linked
    do
        lib-available $formula $link;
        if [ $? -ne 0 ]
        then
            echo "No link available for $link in $formula!";
            return 1;
        fi
    done
    return 0;
}

function check-execs()
{
    formula=$1;
    execdir=$2;
    executables=( `dir $execdir` );
    for executable in $executables
    do
        read
        link-available $executable $formula $execdir;
        if [ $? -ne 0 ]
        then
            echo "$formula is missing a dependency!";
            read;
            return 1;
        fi
    done
}

brew=`which brew`;
prefix=`dirname $brew`/..;
org="homebrew";
tap="core";
tapdir="$prefix/Library/Taps/$org/homebrew-$tap";

# Check for existence of "Formula" folder
if [ -d $tapdir/Formula ]
then
    tapdir="$tapdir/Formula";
fi 

for formulafile in `dir $tapdir`
do
    formula=`basename $formulafile .rb`;
    $brew install -v $formula;
    if [ $? -ne 0 ]
    then
        echo "Installing $formula failed! Skipping."
        continue;
    fi
    execdir="$prefix/opt/$formula/bin";
    check-execs "$formula" "$execdir"
done
