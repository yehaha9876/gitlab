require 'spec_helper'

describe Banzai::Filter::MarkdownBypassFilter do
  include FilterSpecHelper

  it 'moves div child content to parent html' do
    result = filter("<div class='gitlab-markdown-bypass'>My text</div>")

    expect(result.to_html).to eq('My text')
  end

  it 'moves div child content to parent when nested' do
    result = filter("<span><div class='gitlab-markdown-bypass'>My text</div></span>")

    expect(result.to_html).to eq('<span>My text</span>')
  end

  it 'moves div child content to parent when div is deeply nested' do
    result = filter("<ul><li><div class='gitlab-markdown-bypass'>My text</div></li></ul>")

    expect(result.to_html).to eq('<ul><li>My text</li></ul>')
  end

  it 'moves div child content to parent when div and child content are nested' do
    result = filter("<span><div class='gitlab-markdown-bypass'><ul><li>My text</li></ul></div>")

    expect(result.to_html).to eq('<span><ul><li>My text</li></ul></span>')
  end
end
