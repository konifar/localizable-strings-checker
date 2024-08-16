# localizable-strings-checker

[![RSpec Tests](https://github.com/konifar/localizable-strings-checker/actions/workflows/rspec.yml/badge.svg)](https://github.com/konifar/localizable-strings-checker/actions/workflows/rspec.yml)
[![MIT License](https://img.shields.io/github/license/konifar/localizable-strings-checker)][license]

localizable-strings-checker is a GitHub Action to lint and validate localization files, ensuring consistency across different languages in your project.

## Overview

This tool checks Localizable.strings files for the following issues.

### 1. Consistency in keys comparing to base language

In the case that the keys which are only present in the base language file.

```Localizable.strings
/* en.lproj/Localizable.strings (base language) */
"strings_one" = "first strings";
"strings_two" = "second strings";
```

```Localizable.strings
/* ja.lproj/Localizable.strings */
"strings_one" = "1つめの文字列";
```

Detailed message is output if error is found.

```sh
    ...
    Checking for key consistency...
      Keys match: false
      🚨 The following keys are only present in the base language file:
        - strings_two
```

### 2. Consistency in comments comparing to base language

In the case that the number of comments are different between base language and other language.

```Localizable.strings
/* en.lproj/Localizable.strings (base language) */
"strings_one" = "first strings";
/* extra comment */
"strings_two" = "second strings";
```

```Localizable.strings
/* ja.lproj/Localizable.strings */
"strings_one" = "1つめの文字列";
"strings_two" = "2つめの文字列";
```

Detailed message is output if error is found.

```sh
    ...
    Checking for comment consistency...
      Comments match: false
      🚨 The following comments are only present in the base language file:
        - strings_two
```

### 3. Consistency in replacement strings comparing to base language

In the case that the number of replacement strings are different between base language and other language.

```Localizable.strings
/* en.lproj/Localizable.strings (base language) */
"replacable_string" = "%1$@ and %2$@";
```

```Localizable.strings
/* ja.lproj/Localizable.strings */
"replacable_string" = "%1$@";
```

Detailed message is output if error is found.

```sh
    ...
    Checking for the presence of replacement and newline characters...
      🚨 The following keys do not contain the replacement characters:
        - 'replacable_string' does not contain ["%2$@"]
```

### 4. Existence of improper single '%' characters

In the case that the single '%' character exists in Localizable.strings file. '%%' should be used instead of '%'.

```Localizable.strings
/* en.lproj/Localizable.strings (base language) */
"strings_one" = "100%";
```

Detailed message is output if error is found.

```sh
    ...
    Checking if single '%' characters exist...
      🚨 The following keys contain a single % character:
        - 'strings_one' contains a single % character
```

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
