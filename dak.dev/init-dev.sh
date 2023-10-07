#! /bin/bash

echo -n "CONFIGURING DAK ENVIRONMENT ... "
echo 'export PATH="/srv/dak/bin:${PATH}"' > ~/.bashrc
echo 'export PATH="/srv/dak/bin:${PATH}"' > /home/dak/.bashrc
source ~/.bashrc

export ARCH=amd64
export DISTRO_NAME=KSLinux
export DISTRO_VERSION="22.04.3"
export DISTRO_CODENAME=jammy
export DISTRO_REPO_NAME="$DISTRO_NAME $DISTRO_VERSION"
export DISTRO_LABEL="KSL_22_04"
export GPG_KEY="451DD5811062DFC93DF54EEC259531ED17EE37C1"
export GPG_FILE="/dak.dev/keys/.no-key"


USER_CMD="sudo -E -u dak -s -H"
DAK="/srv/dak/bin/dak"
service postgresql start 1>/dev/null 2>&1
service nginx start 1>/dev/null 2>&1
echo "DONE"

echo -n "IMPORTING TEST REPO GPG KEY ... "
$USER_CMD gpg --homedir /srv/dak/keyrings/s3kr1t/dot-gnupg --import $GPG_FILE 1>/dev/null 2>&1
echo DONE

echo -n "IMPORTING TEST DEVELOPER GPG KEY ... "
$USER_CMD gpg --no-default-keyring --keyring /srv/dak/keyrings/upload-keyring.gpg --import $GPG_FILE  1>/dev/null 2>&1
echo "DONE"

echo -n "IMPORTING dak REPO GPG KEY ... "
$USER_CMD $DAK import-keyring -U '%s' /srv/dak/keyrings/upload-keyring.gpg  1>/dev/null 2>&1
echo "DONE"

echo -n "INITING AN EMPTY REPO ... "
$USER_CMD $DAK admin architecture add $ARCH $DISTRO_REPO_NAME 1>/dev/null 2>&1

$USER_CMD $DAK admin suite add-all-arches $DISTRO_CODENAME $DISTRO_VERSION origin=$DISTRO_NAME label=$DISTRO_LABEL codename=$DISTRO_CODENAME signingkey=$GPG_KEY 1>/dev/null 2>&1

$USER_CMD $DAK admin component rm main 1>/dev/null 2>&1
$USER_CMD $DAK admin component rm contrib 1>/dev/null 2>&1
$USER_CMD $DAK admin component rm non-free 1>/dev/null 2>&1
$USER_CMD $DAK admin component rm non-free-firmware 1>/dev/null 2>&1

$USER_CMD $DAK admin component add main main 100 1>/dev/null 2>&1
$USER_CMD $DAK admin component add restricted restricted 110 1>/dev/null 2>&1
$USER_CMD $DAK admin component add universe universe 120 1>/dev/null 2>&1
$USER_CMD $DAK admin component add multiverse multiverse 130 1>/dev/null 2>&1

$USER_CMD $DAK admin s-c add $DISTRO_CODENAME main restricted universe multiverse 1>/dev/null 2>&1

$USER_CMD $DAK init-dirs 1>/dev/null 2>&1

$USER_CMD $DAK generate-packages-sources2 1>/dev/null 2>&1

$USER_CMD $DAK generate-release 1>/dev/null 2>&1
echo "DONE"

debootstrap --no-check-gpg $DISTRO_CODENAME /test file:///srv/dak/ftp 1>/dev/null 2>&1

rm -rvf /test 1>/dev/null 2>&1

ln -s /srv/dak/ftp /var/www/html/kslinux
