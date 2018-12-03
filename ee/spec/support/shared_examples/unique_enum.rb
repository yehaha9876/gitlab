# frozen_string_literal: true

shared_examples 'Unique enum values' do
  it 'has unique values' do
    duplicated = subject.group_by(&:last).select { |key, value| value.size > 1 }

    expect(duplicated).to be_empty,
      "Duplicated values detected: #{duplicated.values.map(&Hash.method(:[]))}"
  end
end
