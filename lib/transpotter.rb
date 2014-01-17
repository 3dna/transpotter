require 'charlock_holmes/string'

class Transpotter
  attr_reader :filename

  DEFAULT_SAMPLE_SIZE = 1024 * 1024 * 500 # 500 MB

  # Determined from here:
  # http://w3techs.com/technologies/overview/character_encoding/all
  MOST_COMMON_ENCODINGS = (%w{
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
  } + Encoding.name_list).uniq.map { |name| Encoding.find(name) }

  ENCODING_ERRORS = [
    Encoding::InvalidByteSequenceError,
    Encoding::UndefinedConversionError,
    Encoding::ConverterNotFoundError
  ]

  def initialize(filename, data = nil, samplesize = nil)
    @samplesize = samplesize || DEFAULT_SAMPLE_SIZE
    @filename = filename
    @data = data
  end

  def encoding
    @encoding ||= (charlock || brute_force)
  end

  def read
    enc = Encoding.find(encoding)
    if @filename
      convert(File.read(@filename, external_encoding: enc))
    elsif @data
      convert(@data)
    end
  end

  def each_line
    enc = Encoding.find(encoding)
    if @filename
      File.open(@filename, external_encoding: enc) do |io|
        io.each(line_endings) { |line| yield convert(line) }
      end
    elsif @data
      convert(@data).split(line_endings).each { |line| yield line }
    end
  end

  private

  def line_endings
    @line_endings = case sample
                    when /\r\n/ then "\r\n"
                    when /\n/ then "\n"
                    when /\r/ then "\r"
                    end
  end

  def convert(string)
    return string if encoding == 'UTF-8'
    @converter ||= Encoding::Converter.new(encoding, 'UTF-8')
    @converter.convert(string)
  end

  def sample
    @sample ||= File.read(@filename, @sample_size) if @filename
    @sample ||= @data
  end

  def charlock
    sample.detect_encoding[:encoding]
  end

  def brute_force
    MOST_COMMON_ENCODINGS.each do |encoding|
      return encoding.name if valid_encoding?(encoding)
    end
    nil
  end

  def valid_encoding?(encoding)
    test_data = sample.force_encoding(encoding.name)
    converter = Encoding::Converter.new(encoding.name, 'UTF-8')
    return converter.convert(test_data).valid_encoding?
  rescue *ENCODING_ERRORS
    return false
  end
end
