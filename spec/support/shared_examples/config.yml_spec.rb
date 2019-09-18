RSpec.shared_examples 'config.yml' do |file_name, params|
  subject(:yaml) { YAML.safe_load(file) }

  let!(:file) {
    path = File.expand_path(File.join(__dir__, '..', '..', '..', 'lib', 'html2rss', 'configs', file_name))
    File.open(path)
  }

  let(:feed_name) { file.path.split(File::Separator)[-2..-1].join(File::Separator) }

  context 'with the file' do
    it 'is parseable' do
      expect { yaml }.not_to raise_error
    end

    it 'resides in a folder named after channel.url\'s host' do
      dirname = File.dirname(file.path).split(File::Separator).last
      host_name = URI(yaml['channel']['url'].split('/')[0..2].join('/')).host.gsub(/(api|www)\./, '')

      expect(dirname).to eq(host_name)
    end
  end

  context 'with file contents' do
    it 'has channel' do
      expect(yaml).to have_key 'channel'
    end

    context 'with channel present' do
      %w[title url ttl time_zone].each do |required_attribute|
        it "has channel.#{required_attribute}" do
          expect(yaml['channel']).to have_key required_attribute
        end
      end

      it 'has a known time_zone' do
        expect {
          Time.find_zone! yaml['channel']['time_zone']
        }.not_to raise_error
      end
    end

    it 'has selectors' do
      expect(yaml).to have_key 'selectors'
    end

    context 'with selectors present' do
      it { expect(yaml['selectors']).to have_key 'items' }

      %w[items title].each do |required_attribute|
        it "has selectors.#{required_attribute}" do
          expect(yaml['selectors'][required_attribute]).not_to be_empty
        end
      end
    end
  end

  context "with fetching #{params}", :fetch do
    subject(:feed) { Html2rss.feed(config) }

    let(:global_config) {
      { 'headers' => {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:67.0) Gecko/20100101 Firefox/67.0'
      } }
    }
    let(:feed_config) {
      params ||= {}
      Html2rss::Configs.find_by_name(feed_name, params)
    }
    let(:config) { Html2rss::Config.new(feed_config, global_config) }

    it 'has positive amount of items' do
      expect(feed.items.count).to be_positive
    end

    context 'with an item' do
      let(:item) { feed.items.first }
      let(:specified_attributes) { %w[title description author category] & config.attribute_names }
      let(:text_attributes) { %w[title description author] & specified_attributes }
      let(:content_attributes) { specified_attributes - text_attributes }
      let(:special_attributes) {
        [].tap do |arr|
          arr << :pubDate if config.attribute_names.include?(:updated)
        end
      }

      it 'has no empty text attributes', :aggregate_failures do
        (text_attributes + special_attributes).each do |attribute_name|
          expect(item.public_send(attribute_name)).not_to be_empty, attribute_name
        end
      end

      it 'has no empty content attributes', :aggregate_failures do
        content_attributes.each do |attribute_name|
          expect(item.public_send(attribute_name).content).not_to be_empty, attribute_name
        end
      end
    end
  end
end
