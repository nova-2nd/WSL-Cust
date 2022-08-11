#!/usr/bin/env bash
# Inspired by https://salsa.debian.org/debian/WSL


set -e

BUILDIR=$(pwd)
PARENTDIR=${PWD##*/}
TMPDIR=$(mktemp -d)

DIST="bullseye"

create_x64_rootfs() {
    rm -f $BUILDIR/../blobs/install.tar.gz
    # rm -f $BUILDIR/blobs/install.tar.xz
	cd $TMPDIR

	sudo cdebootstrap -a "amd64" --exclude=debfoster --include=sudo,locales,ansible,gpg,python3-apt $DIST $DIST http://deb.debian.org/debian

    sudo cp -r $BUILDIR/inject_files/pre-chroot/* $TMPDIR/$DIST

    sudo chroot $DIST /bin/bash -s < $BUILDIR/dist_files/chroot-tasks.sh

    sudo rm -f $DIST/etc/resolv.conf
    sudo rm -f $DIST/etc/hosts
    sudo cp -r $BUILDIR/inject_files/post-chroot/* $TMPDIR/$DIST

    sudo tar -xvf /tmp/opt_distrod.tar.gz -C $DIST/opt/distrod

	cd $DIST
    sudo tar --ignore-failed-read -czvf $BUILDIR/../blobs/install.tar.gz *
	# sudo tar --ignore-failed-read -cJvf $BUILDIR/../blobs/install.tar.xz *
	# mv $TMPDIR/install.tar.gz $BUILDIR/blobs
    # mv $TMPDIR/install.tar.xz $BUILDIR/blobs
    sudo rm -rf $TMPDIR
	cd $BUILDIR
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

