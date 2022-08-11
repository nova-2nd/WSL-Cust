#!/usr/bin/env bash
# Inspired by https://salsa.debian.org/debian/WSL


set -e

BUILDIR=$(pwd)
PARENTDIR=${PWD##*/}

DIST="bullseye"

STATICBOOTSTRAP=0 # Create initial bootstrap folder and keep it for followup runs
# STATICBOOTSTRAP Does not work right now - Don't use - keep it zero!
# Probably the bootstrap cloning (Copy static bootstrap folder) portion ...
STATICBOOTSTRAPFOLDER=/tmp/$DIST-bootstrap
KEEPSTATICBOOTSTRAP=0
# Keep bootstrap folder even when static bootstrap disabled
ONESHOTBOOTSTRAP=0
# Static bootstrap anyway, what ever is configured

if [ $STATICBOOTSTRAP -eq 1 ] ; then
    TMPDIR=$STATICBOOTSTRAPFOLDER
else
    TMPDIR=$(mktemp -d)
    if [ -d $STATICBOOTSTRAPFOLDER ] && [ $KEEPSTATICBOOTSTRAP -eq 0 ]; then
        echo "########################################"
        echo "Delete static bootstrap folder - start"
        echo "----------------------------------------"
        sudo rm -rf $VERBOSEMINUSV $STATICBOOTSTRAPFOLDER
        echo "----------------------------------------"
        echo "Delete static bootstrap folder - done"
        echo "########################################"
    fi
fi

BUILDGZ=1
BUILDXZ=0

VERBOSE=0

if [ $VERBOSE -eq 1 ]; then
    VERBOSEMINUSV="-v"
fi

create_x64_rootfs() {
    if  [ ! -d $TMPDIR ]; then
        sudo mkdir -p $TMPDIR
        ONESHOTBOOTSTRAP=1
    fi
	cd $TMPDIR

    if [ $STATICBOOTSTRAP -eq 0 ] || [ $ONESHOTBOOTSTRAP -eq 1 ] ; then
        echo "########################################"
        echo "Create bootstrap folder - start"
        echo "----------------------------------------"
        sudo cdebootstrap -a "amd64" $VERBOSEMINUSV --exclude=debfoster --include=sudo,locales,ansible,gpg,python3-apt $DIST $DIST http://deb.debian.org/debian
        echo "----------------------------------------"
        echo "Create bootstrap folder - done"
        echo "########################################"
    fi

    if [ $STATICBOOTSTRAP -eq 1 ]; then
        NEWTMP=$(mktemp -d)
        echo "########################################"
        echo "Copy static bootstrap folder - start"
        echo "----------------------------------------"
        sudo cp -ar $VERBOSEMINUSV $TMPDIR/* $NEWTMP
        echo "----------------------------------------"
        echo "Copy static bootstrap folder - done"
        echo "########################################"
        TMPDIR=$NEWTMP

    fi

    echo "########################################"
    echo "Injecting pre-chroot files - start"
    echo "----------------------------------------"
    sudo cp -ar $VERBOSEMINUSV $BUILDIR/inject_files/pre-chroot/* $TMPDIR/$DIST
    echo "----------------------------------------"
    echo "Injecting pre-chroot files - done"
    echo "########################################"

    echo "########################################"
    echo "Execute chroot script - start"
    echo "----------------------------------------"
    sudo chroot $DIST /bin/bash -s < $BUILDIR/dist_files/chroot-tasks.sh
    echo "----------------------------------------"
    echo "Execute chroot script - done"
    echo "########################################"

    echo "########################################"
    echo "Remove chroot files - start"
    echo "----------------------------------------"
    sudo rm -f $VERBOSEMINUSV $DIST/etc/resolv.conf
    sudo rm -f $VERBOSEMINUSV $DIST/etc/hosts
    echo "----------------------------------------"
    echo "Remove chroot files - done"
    echo "########################################"

    echo "########################################"
    echo "Injecting post-chroot files - start"
    echo "----------------------------------------"
    sudo cp -ar $VERBOSEMINUSV $BUILDIR/inject_files/post-chroot/* $TMPDIR/$DIST
    echo "----------------------------------------"
    echo "Injecting post-chroot files - done"
    echo "########################################"

    echo "########################################"
    echo "Injecting distrod - start"
    echo "----------------------------------------"
    sudo tar $VERBOSEMINUSV -xf $BUILDIR/../blobs/opt_distrod.tar.gz -C $TMPDIR/$DIST/opt/distrod
    echo "----------------------------------------"
    echo "Injecting distrod - done"
    echo "########################################"

	cd $DIST

    if [ $BUILDGZ -eq 1 ]; then
        echo "########################################"
        echo "Build gz rootfs - start"
        echo "----------------------------------------"
        sudo tar --ignore-failed-read $VERBOSEMINUSV -czf $BUILDIR/../blobs/$DIST.tar.gz *
        echo "----------------------------------------"
        echo "Build gz rootfs - done"
        echo "########################################"
    fi
    if [ $BUILDXZ -eq 1 ]; then
        echo "########################################"
        echo "Build xz rootfs - start"
        echo "----------------------------------------"
	    sudo tar --ignore-failed-read $VERBOSEMINUSV -cJf $BUILDIR/../blobs/$DIST.tar.xz *
        echo "----------------------------------------"
        echo "Build xz rootfs - done"
        echo "########################################"
    fi

    echo "########################################"
    echo "Remove bootstrap folder - start"
    echo "----------------------------------------"
    sudo rm -rf $VERBOSEMINUSV $TMPDIR
	cd $BUILDIR
    echo "----------------------------------------"
    echo "Remove bootstrap folder - done"
    echo "########################################"
}


if [ -f .root-identifier ]; then
    if [ $(cat .root-identifier) == $PARENTDIR ]; then
        create_x64_rootfs
    else
        echo "Please change to the root of this script and execute it from there!"
        exit 1
    fi
else
    echo "Please change to the root of this script and execute it from there!"
    exit 1
fi

