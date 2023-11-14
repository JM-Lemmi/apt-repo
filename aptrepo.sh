#!/bin/bash

# Das script muss im deb ordner des pkg gestartet werden (zB /var/www/html/deb)

## Sub-Commands as Functions ##

function genbase () {
    # Usage: ./aptrepo init <name> <stable/testing> <description>

    # Generate Release files
    mkdir -p dists/${2}

    cat << EOF > dists/${2}/base.Release
Origin: ${1}
Suite: ${2}
Codename: ${2}
Components: main
Description: ${3}
EOF

    # Generate GPG Key
    # Get Name and Email from Input
    read -p "Enter your name: " name
    read -p "Enter your email: " email

    tmp=$(mktemp)
    cat << EOF > ${tmp}
%echo Generating a PGP key
Key-Type: RSA
Key-Length: 4096
Name-Real: ${name}
Name-Email: ${email}
Expire-Date: 0
%no-ask-passphrase
%no-protection
%commit
EOF

    gpg --no-tty --batch --gen-key ${tmp}
    gpg --armor --export ${email} > gpg.key
}

function genpackages () {
    # benötigt dpkg-dev

    # usage: ./apt-repo add <pkg.deb> <stable/testing>
    # pwd should be the /deb/ folder

    #split package name into information, ${pkg[i]}, 0 package name, 1 semver, 2 arch
    #TODO: this only works if the pkg.deb path contains the full deb name. maybe instead it should be copied to a temp folder and the information extracted by dpkg to create the destination name
    pkgname=${1%.deb} # remove file ending
    pkgname=${pkgname##*/} # remove path
    pkg=(${pkgname//_/ }) # split by _
    pkgindex=${pkg[0]:0:1}

    # copy package to pool
    mkdir -p pool/main/${pkgindex}/${pkg[0]}
    if [[ ${1} =~ http(s):\/\/.* ]]; then
        wget -P pool/main/${pkgindex}/${pkg[0]}/ ${1}
        # TODO overwrite existing file / warn that it isnt named correctly, thus not the file we deal with in the following
    else
        echo "else"
        cp ${1} pool/main/${pkgindex}/${pkg[0]}
    fi

    # Generate Package snippet for current package
    dpkg-scanpackages pool/main/${pkgindex}/${pkg[0]}/${pkgname}.deb > dists/${2}/main/binary-${pkg[2]}/${pkg[0]}.Packages
    cat dists/${2}/main/binary-${pkg[2]}/*.Packages > dists/${2}/main/binary-${pkg[2]}/Packages
    cat dists/${2}/main/binary-${pkg[2]}/Packages | gzip -9 > dists/${2}/main/binary-${pkg[2]}/Packages.gz
}

function genrelease () {
    # benötigt: gpg

    # usage: ./script.sh <stable/testing>
    # pwd should be the /deb/ folder

    cd dists/${1}/

    # load base config and overwrite current release file
    cat base.Release > Release

    # Calculate Hashes for all required files (excludes Release, InRelase, Release.gpg and *.Packages)
    # hacked dict: https://stackoverflow.com/a/4444733
    for h in "MD5Sum:md5sum" "SHA1:sha1sum" "SHA256:sha256sum"; do
        echo "${h%%:*}:" >> Release
        for f in $(find -type f); do
            f=$(echo $f | cut -c3-) # remove ./ prefix
            if [ "$f" = "Release" ] || [ "$f" = "InRelease" ] || [ "$f" = "Release.gpg" ] || [ "$f" = "base.Release" ] || [[ ${f} =~ .*\.Packages ]]; then
                continue
            fi
            echo " $(${h##*:} ${f}  | cut -d" " -f1) $(wc -c $f)" >> Release
        done
    done

    # Read existing architectures from folderstructure
    for d in $(ls --directory main/binary-*); do
        archs+=(${d##*/binary-})
    done
    echo "Architectures: ${archs[@]}" >> Release

    # add current date
    echo "Date: $(date -Ru)" >> Release

    # GPG Sign
    export GPG_TTY=$(tty)
    cat Release | gpg -abs > Release.gpg
    cat Release | gpg -abs --clearsign > InRelease

}

## Selector for Command ##

case "$1" in
init) shift; genbase "$@" ;;
add) shift; genpackages "$@" ;;
release) shift; genrelease "$@" ;;
* ) break ;;
esac
