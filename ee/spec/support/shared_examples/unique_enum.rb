# frozen_string_literal: true

shared_examples 'Unique enum values' do
  it 'has unique values' do
    subject.each do |k, v|
      keys = subject.select { |_, v2| v2 == v }

      expect(keys.length).to eq(1),
        "The value of the key (#{k}) is duplicated with (#{keys.except(k).keys.join(',')}). " \
        "You have to define unique values."
    end
  end
end
