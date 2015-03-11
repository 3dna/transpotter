require 'charlock_holmes/string'

class Transpotter
  attr_reader :filename

  DEFAULT_SAMPLE_SIZE = 1024 * 1024 # 1 MB

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
    return unless sample # don't do anything if we can't grab sample
    if @filename
      open_encoded_file do |io|
        return convert(io.read)
      end
    elsif @data
      convert(@data)
    end
  end

  def each_line
    return unless sample # don't do anything if we can't grab sample
    if @filename
      open_encoded_file do |io|
        io.each(line_endings.encode(@encoding)) { |line| yield convert(line) }
      end
    elsif @data
      convert(@data).split(line_endings).each { |line| yield line }
    end
  end

  private

  def open_encoded_file
    File.open(@filename,
              'rb',
              external_encoding: encoding,
              internal_encoding: encoding) do |io|
      yield io
    end
  end

  def line_endings
    @line_endings = case convert(sample)
                    when /\r\n/ then "\r\n"
                    when /\n/ then "\n"
                    when /\r/ then "\r"
                    else "\n"
                    end
  end

  def convert(string)
    return string if encoding == 'UTF-8'
    string.force_encoding(encoding).encode('UTF-8')
  end

  def sample
    @sample ||= File.read(@filename, @samplesize) if File.file?(@filename.to_s)
    @sample ||= @data
  end

  def charlock
    if sample
      encoding = sample.detect_encoding
      encoding[:encoding] if encoding[:confidence] > 75
    end
  end

  def brute_force
    return nil if sample.nil?
    MOST_COMMON_ENCODINGS.each do |encoding|
      return encoding.name if valid_encoding?(encoding)
    end
    nil
  end

  def valid_encoding?(encoding)
    sample.force_encoding(encoding.name).encode('UTF-8').valid_encoding?
  rescue *ENCODING_ERRORS
    return false
  end
end
