# encoding: utf-8
require 'spec_helper'
require 'tempfile'

describe Transpotter do
  shared_examples 'a transpotter' do
    let(:file) { Tempfile.new('transpotter') }
    let(:encoded_data) { data.encode(encoding, replace: '') }

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
        "圖形碼helloｗ ｘ ｙ ｚ白いÇ  Α Β Γ Δ Ε Ζ Η Θ Ι Κ Λ Μ中文數位化技術推廣委員會"
      end
      let(:encoding) { encoding }

      it_behaves_like 'a transpotter'
    end
  end
end
