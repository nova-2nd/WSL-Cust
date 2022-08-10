#!/usr/bin/env bash
# Inspired by https://salsa.debian.org/debian/WSL


set -e

BUILDIR=$(pwd)
TMPDIR=$(mktemp -d)

DIST="bullseye"

create_x64_rootfs() {
    rm -f $BUILDIR/blobs/install.tar.gz
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
    sudo tar --ignore-failed-read -czvf $TMPDIR/install.tar.gz *
	# sudo tar --ignore-failed-read -cJvf $TMPDIR/install.tar.xz *
	mv $TMPDIR/install.tar.gz $BUILDIR/blobs
    # mv $TMPDIR/install.tar.xz $BUILDIR/blobs
    sudo rm -rf $TMPDIR
	cd $BUILDIR
}

create_x64_rootfs
