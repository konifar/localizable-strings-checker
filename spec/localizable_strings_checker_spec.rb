require 'rspec'
require_relative '../localizable_strings_checker'

RSpec.describe LocalizableStringsChecker do
  describe 'SPECIAL_STRINGS' do
    it 'contains the correct special strings' do
      expected_strings = [
        '%%', '\n', '%s', '%d', '%@',
        '%1$s', '%2$s', '%3$s', '%4$s', '%5$s', '%6$s', '%7$s', '%8$s', '%9$s', '%10$s',
        '%11$s', '%12$s', '%13$s', '%14$s', '%15$s', '%16$s', '%17$s', '%18$s', '%19$s', '%20$s',
        '%1$d', '%2$d', '%3$d', '%4$d', '%5$d', '%6$d', '%7$d', '%8$d', '%9$d', '%10$d',
        '%11$d', '%12$d', '%13$d', '%14$d', '%15$d', '%16$d', '%17$d', '%18$d', '%19$d', '%20$d',
        '%1$@', '%2$@', '%3$@', '%4$@', '%5$@', '%6$@', '%7$@', '%8$@', '%9$@', '%10$@',
        '%11$@', '%12$@', '%13$@', '%14$@', '%15$@', '%16$@', '%17$@', '%18$@', '%19$@', '%20$@'
      ]

      expected_strings.each do |str|
        expect(LocalizableStringsChecker::SPECIAL_STRINGS).to include(str)
      end
    end

    it 'contains the incorrect special strings' do
      expected_strings = [
        '%',
        '%21$s',
        '%21$d',
        '%21$@'
      ]

      expected_strings.each do |str|
        expect(LocalizableStringsChecker::SPECIAL_STRINGS).not_to include(str)
      end
    end
  end

  describe '#check_single_percent_string' do
    let(:checker) { LocalizableStringsChecker.new('/dummy/path', 'ja') }

    it 'returns false when no single % characters are present' do
      key_values = [
        { 'key1' => 'This is a test string with %% and %s' },
        { 'key2' => 'Another string with %1$s and %2$d' }
      ]
      result = checker.send(:check_single_percent_string, key_values, '/dummy/path')
      expect(result).to be false
    end

    it 'returns false and logs an error when single % characters are present' do
      key_values = [
        { 'key1' => 'This string has a single % character' },
        { 'key2' => 'Another string with %1$s and %2$d' }
      ]
      expect {
        result = checker.send(:check_single_percent_string, key_values, '/dummy/path')
        expect(result).to be true
      }.to output(/'key1' contains a single % character/).to_stdout
    end
  end
end
