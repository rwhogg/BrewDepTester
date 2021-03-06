#!/usr/bin/env zsh

# Hardcoded list of exceptions (libraries provided by glibc or an explicit system dependency)
exceptions=( "ld-linux-x86-64.so.2" "libc.so.6" "libm.so.6" "libutil.so.1" "libpthread.so.0" "libstdc++.so.6" "librt.so.1" "libdl.so.2" );

# Initial tap setup
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

function lib-available()
{
    formula=$1;
    lib=$2;
    prefix=$3;
    deps=( `$brew deps $formula` );
    for exception in $exceptions
    do
        if [ "x$exception" = "x$link" ]
        then
            return 0;
        fi
    done
    for dep in $deps $formula
    do
	shortdep=`basename $dep`;
        deplibdir=$prefix/opt/$shortdep/lib;
	if [ ! -d $deplibdir ]
	then
	    continue;
	fi
	deplibs=( `dir $deplibdir` );
	for deplib in $deplibs
	do
	    if [ "x$deplib" = "x$lib" ]
	    then
		return 0;
	    fi
	done
    done
    return 1;
}

function link-available()
{
    executable=$1;
    formula=$2;
    prefix=$3;
    linked=( `patchelf --print-needed $execdir/$executable 2> /dev/null` );

    if [ $? -ne 0 ]
    then
        return 0;
    fi
    
    for link in $linked
    do
        if [ "x$link" = "xlibstdc++.so.6" ]
        then
            echo "$formula requires C++";
        fi
        lib-available $formula $link $prefix;
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
    prefix=$2;
    execdir="$prefix/opt/$formula/bin";
    if [ ! -d $execdir ]
    then
	return 0;
    fi
    executables=( `dir $execdir` );
    for executable in $executables
    do
        link-available $executable $formula $prefix;
        if [ $? -ne 0 ]
        then
            return 1;
        fi
    done
    return 0;
}

# Entrypoint
for formulafile in `ls -x $tapdir`
do
    formula=`basename $formulafile .rb`;
    echo "Checking $formula!";
    $brew install $formula 1> /dev/null 2>&1;
    if [ $? -ne 0 ]
    then
        echo "Installing $formula failed! Skipping."
        continue;
    fi

    check-execs "$formula" "$prefix"
done
