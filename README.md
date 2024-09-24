# License-Scanner

This project implements a bash script that scans source code files for license headers. The script identifies common license types such as LGPL, GPL, and ADI-BSD, and can also report files without any license headers.

## Usage

```bash
Usage: license_scanner.sh --path /path/to/directory [options]
Scan files for licenses.
Options:
    -d, --dirs          Comma-separated list of directory names to omit.
                        Example: license_scanner.sh --dirs build,examples

    -f, --files         Comma-separated list of file names to omit.
                        Example: license_scanner.sh --files LICENSE,README.md

    -p, --path          Path of the base directory to scan.
                        Example: license_scanner.sh --path /path/to/directory

    -h, --help          Display this help message.

    -v, --verbose       Display verbose output.
```

## Features

- [ ] **Automated License Validation in CI/CD**: integrate with Continuous Integration pipelines to ensure that all source files have the correct license header.
  - [ ] Generate failure reports for files without proper licensing during automated builds.
- [ ] **Add License Header to Files Without License**: automatically add license headers to files that are missing them.
  - [ ] **Search for License File**: Automatically detect a `LICENSE` file in the project root and extract the license type from it (e.g., MIT, LGPL, GPL).
  - [ ] **Customizable License Templates**: Define flexible templates for each license type, allowing adaptation to different projects and file types.
    - [ ] Templates accept parameters like year, project name, and author.
    - [ ] Automatically determine the comment syntax for different file types (e.g., C, Python, HTML).
  - [ ] **File-Specific Header Insertion**: Ensure that headers are inserted in the correct format for each file type (e.g., C-style block comments for `.c` files, Python-style hash comments for `.py` files).
- [ ] **License Header Removal or Update**: provide the option to update outdated license headers or remove incorrect ones.
  - [ ] Match and remove outdated license headers based on a template pattern or keywords.
  - [ ] Update license year or other fields if needed (e.g., change copyright year dynamically).
- [ ] **Dry-Run Mode**: preview changes without modifying any files to ensure correctness before applying them.
