require 'apfel'
require 'find'

class LocalizableStringsChecker
  # Define special strings like replacement and newline characters
  SPECIAL_STRINGS = [
    '%%', '\n', '%s', '%d', '%@',
    *('s d @'.split.flat_map { |suffix| (1..20).map { |n| "%#{n}$#{suffix}" } })
  ].freeze

  # @param root_dir [String] The root directory of the project
  # @param base_lang [String] The language code of the base language like 'ja'
  def initialize(root_dir, base_lang)
    @root_dir = root_dir
    @base_lang = base_lang
    @errors = []
  end

  def run
    # Get all lang directories in the project
    lang_dirs = Dir.glob("#{@root_dir}/**/Languages")
    puts "Target lang directories count: #{lang_dirs.length}"

    lang_dirs.each do |lang_dir|
      process_lang_dir(lang_dir)
    end

    unless @errors.empty?
      puts "🚨 Errors found:"
      @errors.each do |error|
        puts "  #{error[:file]}:"
        error[:messages].each { |message| puts "    #{message}" }
      end
      exit 1
    else
      puts "✅ No errors found!"
    end
  end

  private

  # @param lang_dir [String] Path to the language directory
  def process_lang_dir(lang_dir)
    puts "🔄 Language directory: #{lang_dir}"
    
    base_path = "#{lang_dir}/#{@base_lang}.lproj/Localizable.strings"
    unless File.exist?(base_path)
      puts "  Error: base language file not found in #{base_path}."
      add_error_message(base_path, "Base language file not found.")
    end

    base_file = Apfel.parse(base_path)
    
    puts "  Checking base file: #{base_path}"
    has_single_percent = check_single_percent_string(base_file.key_values, base_path)
    if has_single_percent
      @errors << { file: base_path, messages: ["Base language file contains a single % character."] }
    end

    # Process other languages
    other_files = Dir.glob("#{lang_dir}/*.lproj").reject { |dir| dir.include?("#{@base_lang}.lproj") }
    other_files.each { |other_file| process_other_file(other_file, base_file, lang_dir) }
  end

  # @param other_file [String] Path to the other language file
  # @param base_file [Apfel::Strings] Parsed base language file
  # @param lang_dir [String] Path to the language directory
  def process_other_file(other_file, base_file, lang_dir)
    puts "  Checking other file: #{other_file}"

    # 言語ディレクトリ内のLocalizable.stringsファイルを探索
    Find.find(lang_dir) do |path|
      next unless path =~ /.*\.lproj\/Localizable.strings$/ && path !~ /#{@base_lang}\.lproj/

      # 他言語ファイルを解析
      other_file = Apfel.parse(path)
      puts "    Loading #{path}, keys count: #{other_file.keys.length}"

      # 各種チェックを実行
      perform_checks(base_file, other_file, path)
    end
  end

  def add_error_message(file, message)
    existing_error = @errors.find { |error| error[:file] == file }
    if existing_error
      existing_error[:messages] << message
    else
      @errors << { file: file, messages:[message] }
    end
  end

  # @param base_file [Apfel::Strings] 基準言語ファイルの解析結果
  # @param other_file [Apfel::Strings] 他言語ファイルの解析結果
  # @param path [String] 他言語ファイルのパス
  def perform_checks(base_file, other_file, path)
    is_same_keys = check_same_keys(base_file.keys, other_file.keys, path)
    unless is_same_keys
      add_error_message(path, "Keys are not matched")
    end

    is_same_comments = check_same_comments(base_file.comments, other_file.comments, path)
    unless is_same_comments
      add_error_message(path, "Comments are not matched")
    end

    is_replace_strings = check_replace_strings(base_file.key_values, other_file.key_values, path)
    unless is_replace_strings
      add_error_message(path, "The number of replace strings are not matched")
    end

    has_single_percent = check_single_percent_string(other_file.key_values, path)
    if has_single_percent
      add_error_message(path, "Single percent characters are not matched")
    end
  end

  # Check for key consistency
  # @param base_keys [Array<String>] Base language keys
  # @param other_keys [Array<String>] Other language keys
  # @param path [String] Path to the other language file
  # @return [Boolean] Whether the keys match
  def check_same_keys(base_keys, other_keys, path)
    puts "    Checking for key consistency..."
    sorted_base_keys = base_keys.sort
    sorted_other_keys = other_keys.sort
    is_same_keys = sorted_base_keys == sorted_other_keys
    puts "      Keys match: #{is_same_keys}"

    unless is_same_keys
      missing_keys = sorted_base_keys - sorted_other_keys
      if missing_keys.any?
        puts "      🚨 The following keys are only present in the base language file:"
        missing_keys.each { |key| puts "        - #{key}" }
      end
    end
    is_same_keys
  end

  # Check for comment consistency
  # @param base_comments [Array<String>] Base language comments
  # @param other_comments [Array<String>] Other language comments
  # @param path [String] Path to the other language file
  # @return [Boolean] Whether the comments match
  def check_same_comments(base_comments, other_comments, path)
    puts "    Checking for comment consistency..."
    sorted_base_comments = base_comments.sort
    sorted_other_comments = other_comments.sort
    is_same_comments = sorted_base_comments == sorted_other_comments
    puts "      Comments match: #{is_same_comments}"

    unless is_same_comments
      missing_comment_keys = base_comments.keys - other_comments.keys
      if missing_comment_keys.any?
        puts "      🚨 The following comments are only present in the base language file:"
        missing_comments.each { |comment| puts "        - #{comment}" }
      end
    end
    is_same_comments
  end

  # Check for the presence of replacement and newline characters
  # @param base_key_values [Array<Hash>] Base language key-value pairs
  # @param other_key_values [Array<Hash>] Other language key-value pairs
  # @param path [String] Path to the other language file
  # @return [Boolean] Whether all special characters exist in the other language file
  def check_replace_strings(base_key_values, other_key_values, path)
    puts "    Checking for the presence of replacement and newline characters..."
    regex = Regexp.union(SPECIAL_STRINGS.map { |str| Regexp.escape(str) })

    diff_list = base_key_values.each_with_object([]) do |key_value, list|
      key, value = key_value.first
      matches = value.scan(regex).uniq
      next if matches.empty?

      other_value = other_key_values.find { |hash| hash.key?(key) }&.[](key)
      missing_strings = matches.reject { |str| other_value&.include?(str) }
      list << [key, missing_strings] if missing_strings.any?
    end

    unless diff_list.empty?
      puts "      🚨 The following keys do not contain the replacement characters:"
      diff_list.each do |key, missing|
        puts "        - '#{key}' does not contain #{missing}"
      end
      return false
    end
    true
  end

  # Check for single '%' characters
  # @param key_values [Array<Hash>] Key-value pairs
  # @param path [String] File path
  # @return [Boolean] Whether there are no improper '%' characters
  def check_single_percent_string(key_values, path)
    puts "    Checking the single '%' characters exist..."

    single_character_keys = key_values.map do |key_value|
      key, value = key_value.first
      if value.match?(/(?<!%)%(?![%@dsf]|[0-9]+\$[@dsf])/)
        key
      end
    end

    has_single_percent = single_character_keys.compact.any?
    if has_single_percent
      puts "      🚨 The following keys contain a single % character:"
      single_character_keys.compact.each do |key|
        puts "        - '#{key}' contains a single % character"
      end
    end

    has_single_percent
  end
end

if __FILE__ == $PROGRAM_NAME
  root_dir, base_lang = ARGV
  unless root_dir && base_lang
    puts "Usage: ruby #{$0} <project root path> <base language code>"
    exit 1
  end

  LocalizableStringsChecker.new(root_dir, base_lang).run
end
