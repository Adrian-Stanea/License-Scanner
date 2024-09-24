#!/bin/bash

# set -x

# Initialize global variables
OMITTED_DIRS=()
OMITTED_FILES=()
BASE_DIR_PATH=""
FILES_WITHOUT_LICENSE=()
VERBOSE=false

# Define colors used for logging
NC='\033[0m'        # No Color
GREEN='\033[0;32m'  # Files with LGPL license
BLUE='\033[0;34m'   # Files with GPL license
YELLOW='\033[1;33m' # Files with ADI-BSD license
RED='\033[0;31m'    # Files with no license header

function usage() {
    cat <<EOF
    Usage: license_scanner.sh --path /path/to/directory [options]
    Scan files for licenses.
    Options:
        -d, --dirs          Comma-separated list of directory names to omit.
                            Example: license_scanner.sh --dirs=build,examples

        -f, --files         Comma-separated list of file names to omit.
                            Example: license_scanner.sh --files=LICENSE,README.md

        -p, --path          Path of the base directory to scan.
                            Example: license_scanner.sh --path /path/to/directory

        -h, --help          Display this help message.

        -v, --verbose       Display verbose output.

EOF
}

# #############################################################################
# Parse options
LONG_OPTS=dirs:,files:,path:,help,verbose
OPTIONS=d:f:p:h:v
VALID_ARGS=$(getopt --options=$OPTIONS --longoptions=$LONG_OPTS --name "$0" -- "$@")

if [[ $? -ne 0 ]]; then
    exit 1
fi

eval set -- "$VALID_ARGS"

getopt --test >/dev/null && true
if [[ $? -ne 4 ]]; then
    echo "$(getopt --test) failed in this environment."
    exit 1
fi

while true; do
    case "$1" in
    -d | --dirs)
        shift
        IFS="," read -ra OMITTED_DIRS <<<"$1"
        shift
        ;;
    -f | --files)
        shift
        IFS="," read -ra OMITTED_FILES <<<"$1"
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    -p | --path)
        BASE_DIR_PATH="$2"
        shift 2
        ;;
    -v | --verbose)
        VERBOSE=true
        shift
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: -$OPTARG" >&2
        exit 3
        ;;
    esac
done
# #############################################################################

function validate_base_path() {
    if [[ -z "$BASE_DIR_PATH" ]] || [[ ! -d "$BASE_DIR_PATH" ]]; then
        echo "Error: The --path argument is invalid" >&2
        exit 4
    fi
}

function is_LGPL() {
    local file="$1"

    # Check if file exists and is readable
    if [[ ! -f "$file" || ! -r "$file" ]]; then
        echo "Error: File '$file' does not exist or is not readable." >&2
        return 1
    fi

    local lgpl_patterns=(
        "GNU\s*Lesser\s*General\s*Public\s*License" # Standard LGPL reference
        "LGPL"                                      # Short form LGPL
        "LGPLv[23](\.[01])?"                        # Specific verion of LGPL
        "Lesser\s*General\s*Public\s*License,\s*Version\s*[23](\.[01])?"
    )
    local pattern
    pattern=$(
        IFS="|"
        echo "${lgpl_patterns[*]}"
    )

    if grep --quiet --ignore-case --null-data --extended-regexp "$pattern" "$file"; then
        return 0
    else
        return 1
    fi
}

function is_GPL() {
    local file="$1"

    # Check if file exists and is readable
    if [[ ! -f "$file" || ! -r "$file" ]]; then
        echo "Error: File '$file' does not exist or is not readable." >&2
        return 1
    fi

    # TODO: review way to avoid mismatch between GLP and LGPL since the pattern is similar
    # local abort_pattern="The\s*GNU\s*General\s*Public\s*License\s*does\s*not\s*permit\s*incorporating\s*your\s*program.*use\s*the\s*GNU\s*Lesser\s*General\s*Public\s*License\s*instead\s*of\s*this\s*License"
    # if grep --ignore-case --quiet --null-data "$abort_pattern" "$file"; then
    #     return 2
    # fi

    local gpl_patterns=(
        "GNU\s*General\s*Public\s*License" # Standard GPL reference
        "GPL"                              # Short form GPL
    )
    local pattern
    pattern=$(
        IFS="|"
        echo "${gpl_patterns[*]}"
    )

    if grep --quiet --ignore-case --null-data --extended-regexp "$pattern" "$file"; then
        return 0
    else
        return 3
    fi
}

function is_ADI_BSD() {
    local file="$1"

    # Check if file exists and is readable
    if [[ ! -f "$file" || ! -r "$file" ]]; then
        echo "Error: File '$file' does not exist or is not readable." >&2
        return 1
    fi
    local adi_bsd_patterns=(
        "THIS\s*SOFTWARE\s*IS\s*PROVIDED\s*BY\s*ANALOG\s*DEVICES\s*\"?AS\s*IS\"?"
        "IMPLIED\s*WARRANTIES,\s*INCLUDING,\s*BUT\s*NOT\s*LIMITED\s*TO,\s*NON-INFRINGEMENT"
        "MERCHANTABILITY\s*AND\s*FITNESS\s*FOR\s*A\s*PARTICULAR\s*PURPOSE\s*ARE\s*DISCLAIMED"
        "IN\s*NO\s*EVENT\s*SHALL\s*ANALOG\s*DEVICES\s*BE\s*LIABLE\s*FOR\s*ANY\s*DIRECT,\s*INDIRECT"
        "INCLUDING,\s*BUT\s*NOT\s*LIMITED\s*TO,\s*INTELLECTUAL\s*PROPERTY\s*RIGHTS"
        "LOSS\s*OF\s*USE,\s*DATA,\s*OR\s*PROFITS;\s*OR\s*BUSINESS\s*INTERRUPTION"
        "WHETHER\s*IN\s*CONTRACT,\s*STRICT\s*LIABILITY,\s*OR\s*TORT\s*\(INCLUDING\s*NEGLIGENCE\)"
        "EVEN\s*IF\s*ADVISED\s*OF\s*THE\s*POSSIBILITY\s*OF\s*SUCH\s*DAMAGE"
    )
    local pattern
    pattern=$(
        IFS="|"
        echo "${adi_bsd_patterns[*]}"
    )

    if grep --ignore-case --quiet --null-data --extended-regexp "$pattern" "$file"; then
        return 0
    else
        return 1
    fi
}

function has_license_disclaimer() {
    local file="$1"

    # Check if file exists and is readable
    if [[ ! -f "$file" || ! -r "$file" ]]; then
        echo "Error: File '$file' does not exist or is not readable." >&2
        return 1
    fi
    local license_patterns=(
        "license"
        "copyright"
        "disclaimer"
        "reserved"
    )
    local pattern
    pattern=$(
        IFS="|"
        echo "${license_patterns[*]}"
    )

    if grep --quiet --ignore-case --null-data --extended-regexp "$pattern" "$file"; then
        return 0
    else
        return 1
    fi
}

function identify_license() {
    local file=$1
    local relative_path
    relative_path=$(realpath --relative-to="$BASE_DIR_PATH" "$file")
    local depth indent
    depth=$(echo "$relative_path" | awk -F'/' '{print NF-1}')
    indent=$(printf "%*s" $((depth * 4)) "")

    if ! has_license_disclaimer "$file"; then
        FILES_WITHOUT_LICENSE+=("$relative_path")

        if $VERBOSE; then
            echo -e "${indent}${RED}├── $relative_path (No License)${NC}"
        fi
    elif is_LGPL "$file"; then
        if $VERBOSE; then
            echo -e "${indent}${GREEN}├── $relative_path (LGPL)${NC}"
        fi
    elif is_GPL "$file"; then
        if $VERBOSE; then
            echo -e "${indent}${BLUE}├── $relative_path (GPL)${NC}"
        fi
    elif is_ADI_BSD "$file"; then
        if $VERBOSE; then
            echo -e "${indent}${YELLOW}├── $relative_path (ADI-BSD)${NC}"
        fi
    fi
}

function count_licenses() {
    local file=$1
    ((total_checks++))
    if ! has_license_disclaimer $file; then
        ((no_license_count++))
    elif is_LGPL $file; then
        ((lgpl_count++))
    elif is_GPL $file; then
        ((gpl_count++))
    elif is_ADI_BSD $file; then
        ((adi_bsd_count++))
    fi
}

function scan_directory() {
    local BASE_DIR_PATH=$1
    local dir_excludes file_excludes
    dir_excludes=()
    file_excludes=()

    # Use the --build option to exclude directories
    if [ ${#OMITTED_DIRS[@]} -gt 0 ]; then
        for dir in "${OMITTED_DIRS[@]}"; do
            dir_excludes+=(-o -iname "$dir")
        done
        dir_excludes=(-type d \( -iname "${dir_excludes[@]:2}" \) -prune)
    fi
    # Use the --files option to exclude files
    if [ ${#OMITTED_FILES[@]} -gt 0 ]; then
        for file in "${OMITTED_FILES[@]}"; do
            file_excludes+=(-o -iname "$file")
        done
        file_excludes=(-type f ! \( -iname "${file_excludes[@]:2}" \))
    fi

    # Build the find command
    find_cmd=(find "$BASE_DIR_PATH")

    if [ ${#dir_excludes[@]} -gt 0 ]; then
        find_cmd+=("${dir_excludes[@]}")
    fi

    if [ ${#file_excludes[@]} -gt 0 ]; then
        if [ ${#dir_excludes[@]} -gt 0 ]; then
            find_cmd+=(-o)
        fi
        find_cmd+=("${file_excludes[@]}")
    else
        find_cmd+=(-o)
    fi

    find_cmd+=(-print)

    "${find_cmd[@]}"
}

function main() {
    total_checks=0
    no_license_count=0
    lgpl_count=0
    gpl_count=0
    adi_bsd_count=0

    # Count licenses in the files
    while read -r file; do
        if [[ -f "$file" ]]; then
            count_licenses "$file"
        fi
    done < <(scan_directory "$BASE_DIR_PATH" | sort)

    echo -e "License count summary:"
    echo -e "LGPL : [$lgpl_count/$total_checks]"
    echo -e "GPL: [$gpl_count/$total_checks]"
    echo -e "ADI-BSD: [$adi_bsd_count/$total_checks]"
    echo -e "No-license: [$no_license_count/$total_checks]\n"

    if $VERBOSE; then
        echo "Scanning project for license headers from path: $BASE_DIR_PATH ..." >&2
    fi
    while read -r file; do
        if [[ -f "$file" ]]; then
            identify_license "$file"
        fi
    done < <(scan_directory "$BASE_DIR_PATH" | sort)

    if [ ${#FILES_WITHOUT_LICENSE[@]} -gt 0 ]; then
        echo -e "\nPath to files without a license:"
        for file in "${FILES_WITHOUT_LICENSE[@]}"; do
            echo -e "$file"
        done
    else
        echo "All files have a license."
    fi
}

main
