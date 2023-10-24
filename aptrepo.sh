#!/bin/bash

# benötigt dpkg-dev gpg

# usage: ./script.sh <pkg.deb> <stable/testing>
# pwd should be the /deb/ folder

#split package name into information, ${pkg[i]}, 0 package name, 1 semver, 2 arch
pkgname=${1%.deb} # remove file ending
pkgname=${pkgname##*/} # remove path
pkg=(${pkgname//_/ }) # split by _
pkgindex=${pkg[0]:0:1}

# Generate Packages
dpkg-scanpackages --arch ${pkg[2]} pool/main/${pkgindex}/${pkg[0]}/${1} > dists/${2}/main/binary-${pkg[2]}/Packages
cat dists/${2}/main/binary-${pkg[2]}/Packages | gzip -9 > dists/${2}/main/binary-${pkg[2]}/Packages.gz

# Generate Release files
cd dists/${2}

cat << EOF > Release
Origin: JM-Lemmi Repository
Suite: ${2}
Codename: ${2}
Architectures: ${pkg[2]}
Components: main
Description: Julian Lemmerich's apt repository
Date: $(date -Ru)
EOF

# hacked dict: https://stackoverflow.com/a/4444733
for h in "MD5Sum:md5sum" "SHA1:sha1sum" "SHA256:sha256sum"; do
    echo "${h%%:*}:" >> Release
    f=$(echo $f | cut -c3-) # remove ./ prefix
    for f in $(find -type f); do
        if [ "$f" = "Release" ]; then
            continue
        fi
        echo " $(${h##*:} ${f}  | cut -d" " -f1) $(wc -c $f)" >> Release
    done
done

# GPG Sign
export GPG_TTY=$(tty)
cat Release | gpg -abs > Release.gpg
cat Release | gpg -abs --clearsign > InRelease

cd ../..
