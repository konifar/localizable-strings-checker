# localizable-strings-checker

localizable-strings-checker is a GitHub Action to lint and validate localization files, ensuring consistency across different languages in your project.

## Overview

This tool checks Localizable.strings files below.
- Consistency in keys comparing to base language
- Consistency in comments comparing to base language
- Consistency in replacement strings comparing to base language
- Existence of improper single '%' characters

Detailed messages are output if errors are found.


## Usage

This works on GitHub Actions like below.

```yml
# .github/workflows/lint-localizable-strings.yml
name: Lint Localizable.strings

on:
  pull_request:
    branches:
      - main

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Lint Action
        uses: konifar/localizable-strings-checker@v1
        with:
          # Project root path to check Localizable.strings. Default is current directory.
          # project-root-path: "./"
          # Base language code to check other language files like 'ja', 'en', prefix of xx.lproj
          base-lang-code: "ja"
```

## Contribution

Contributions are welcome. Please report bugs or suggest features via Issues. Pull requests are also appreciated.

### Setup
1. Clone this repository

```sh
git clone https://github.com/konifar/localizable-strings-checker.git
cd localizable-strings-checker
```

2. Install the required gems
```sh
bundle install
```

3. Run command to the example project

```sh
ruby ./localizable_strings_checker.rb example ja
```


## License
This project is licensed under the MIT License. See the LICENSE file for details.
