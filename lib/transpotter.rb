class Transpotter
  attr_reader :filename, :encoding

  DEFAULT_SAMPLE_SIZE = 1024 * 1024 * 500 # 500 MB

  # Determined from here:
  # http://w3techs.com/technologies/overview/character_encoding/all
  MOST_COMMON_ENCODINGS = %w{
    UTF-8
    ISO-8859-1
    Windows-1251
    GB2312
    SJIS
    Windows-1252
    GBK
    ISO-8859-2
    EUC-JP
    Windows-1256
    ISO-8859-15
    ISO-8859-9
    EUC-KR
    Windows-1250
    Windows-1254
    Big5
    Windows-874
    US-ASCII
    TIS-620
  }.map { |name| Encoding.find(name) }

  ENCODING_ERRORS = [
    Encoding::InvalidByteSequenceError,
    Encoding::UndefinedConversionError,
    Encoding::ConverterNotFoundError
  ]

  def initialize(filename, samplesize = nil)
    @samplesize = samplesize || DEFAULT_SAMPLE_SIZE
    @filename = filename
  end

  def detect!
    @encoding ||= brute_force
  end

  def output_to(filename)
    detect!
    converter = Encoding::Converter.new(@encoding, 'UTF-8')
    encoding = Encoding.find(@encoding)
    File.open(@filename, external_encoding: encoding) do |in_io|
      File.open(filename, 'w') do |out_io|
        in_io.each do |line|
          out_io.write converter.convert(line)
        end
      end
    end
  end

  private

  def brute_force
    data = File.read(@filename, @sample_size) || ''
    MOST_COMMON_ENCODINGS.each do |encoding|
      return encoding.name if valid_encoding?(data, encoding)
    end
    nil
  end

  def valid_encoding?(data, encoding)
    test_data = data.force_encoding(encoding.name)
    return false unless data.valid_encoding?
    converter = Encoding::Converter.new(encoding.name, 'UTF-8')
    converted_string = converter.convert(test_data)
    return converted_string.valid_encoding?
  rescue *ENCODING_ERRORS
    return false
  end
end
