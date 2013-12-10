require 'spec_helper'
require 'tempfile'

describe Transpotter do
  {
    File.join(FIXTURE_ROOT, 'iso-8859-1-french.txt')  => 'ISO-8859-1',
    File.join(FIXTURE_ROOT, 'iso-8859-1-german.txt')  => 'ISO-8859-1',
    File.join(FIXTURE_ROOT, 'big5.txt')               => 'Big5',
    File.join(FIXTURE_ROOT, 'sjis.txt')               => 'SJIS',
  }.each do |file, encoding|
    context encoding do
      let(:spotter) { Transpotter.new(file) }
      let(:tempfile) { Tempfile.new('transpotter') }

      it 'should detect the correct encoding' do
        spotter.detect!
        spotter.encoding.should eq encoding
      end

      it 'can write a new utf8 file' do
        spotter.output_to(tempfile.path)
        File.readlines(tempfile.path).count.should eq File.readlines(file).count
        File.read(tempfile.path).should be_valid_encoding
        File.read(tempfile.path).encoding.should eq Encoding.find('UTF-8')
        puts File.read(tempfile.path)
      end
    end
  end
end
