#!/bin/sh

arg1="$1"

script_dir=$(cd $(dirname "$0"); pwd)
pkg_name="se3-clients-linux"

cd "$script_dir" || {
    echo "Error, impossible to change directory to $script_dir."
    echo "End of the script."
    exit 1
}

# Remove old *.deb files.
rm -rf "$script_dir/"*.deb

cp -ra "$script_dir/../src" "$script_dir/$pkg_name"

if [ "$arg1" = "update-version" ]
then
    # Update the version number.
    commit_id=$(git log --format="%H" -n 1 | sed -r 's/^(.{10}).*$/\1/')
    epoch=$(date '+%s')
    # It's better to prefix by "0." to have a version number
    # lower than the version numbers of the stable and
    # official releases.
    version="0.${epoch}~${commit_id}"
    sed -i -r "s/^Version:.*$/Version: ${version}/" "$script_dir/se3-clients-linux/DEBIAN/control"
fi


# Insertion of lib.sh where it's needed.
PROG_AWK_LIBSH_INSERTION=$(cat <<'EOS'
{
    if ($0 ~ /^###LIBSH###/) {
      system("cat '__LIBSH__'")
    } else {
      print $0
    }
}
EOS
)

PROG_AWK_LIBSH_INSERTION=$(
    printf '%s\n' "$PROG_AWK_LIBSH_INSERTION" | sed "s|__LIBSH__|$script_dir/$pkg_name/home/netlogon/clients-linux/lib.sh|"
)

for f in "$script_dir/$pkg_name/home/netlogon/clients-linux/distribs/"*"/integration/integration_"*".bash"
do
    if grep -q '^###LIBSH###' "$f"
    then
        tmp_f=$(mktemp)
        awk "$PROG_AWK_LIBSH_INSERTION" "$f" > "$tmp_f"
        cat "$tmp_f" > "$f"
        rm -f "$tmp_f"
    fi
done

# Build.
dpkg --build "$script_dir/$pkg_name" .

# Cleaning.
rm -r "$script_dir/$pkg_name"


