# encoding: utf-8
require 'spec_helper'
require 'tempfile'

describe Transpotter do
  shared_examples 'a transpotter' do
    let(:file) { Tempfile.new('transpotter') }
    let(:encoded_data) do
      data.encode(encoding, replace: '')
    end

    before do
      File.open(file.path, 'w') do |io|
        io.write encoded_data
      end
    end

    context 'file' do
      let(:spotter) { Transpotter.new(file.path) }

      it 'can detect the encoding of a file' do
        spotter.encoding.should eq encoding
      end

      it 'can see every line' do
        spotter.each_line { |line| line.encoding.name.should eq 'UTF-8' }
      end

      it 'can read the whole document' do
        expect(spotter.read.encoding.name).to eq 'UTF-8'
      end
    end

    context 'data' do
      let(:spotter) { Transpotter.new(nil, encoded_data) }

      it 'can detect the encoding of a file' do
        spotter.encoding.should eq encoding
      end

      it 'can see every line' do
        spotter.each_line { |line| line.encoding.name.should eq 'UTF-8' }
      end
    end
  end

  %w{
    UTF-8
    ISO-8859-1
    Big5
    Shift_JIS
  }.each do |encoding|
    context encoding do
      let(:data) do
        "圖形碼helloｗ ｘ ｙ ｚ白いÇ  Α Β Γ Δ Ε Ζ Η Θ Ι Κ Λ Μ中文數位化技術推廣委員會" * 1025
      end
      let(:encoding) { encoding }

      it_behaves_like 'a transpotter'
    end
  end

  context 'nil input' do
    it 'will not break if nil is given' do
      spotter = Transpotter.new(nil, nil)
      spotter.each_line { fail 'should not be called' }
    end

    it 'will return no encoding if no data is given' do
      Transpotter.new(nil, nil).encoding.should be_nil
    end
  end

  context 'bad file' do
    it 'will return nothing if an invalid file is provided' do
      Transpotter.new('path/to/no/where').each_line { fail }
    end

    it 'will return no encoding if an invalid file is provided' do
      Transpotter.new('path/to/no/where').encoding.should be_nil
    end

    it 'will return nothing if an invalid file is provided' do
      Transpotter.new('/dev/null').encoding.should be_nil
    end
  end
end
