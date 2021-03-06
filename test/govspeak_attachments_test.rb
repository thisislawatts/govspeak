# encoding: UTF-8

require 'test_helper'

class GovspeakAttachmentTest < Minitest::Test
  def build_attachment(args = {})
    {
      content_id: "2b4d92f3-f8cd-4284-aaaa-25b3a640d26c",
      id: 456,
      url: "http://example.com/attachment.pdf",
      title: "Attachment Title",
    }.merge(args)
  end

  def compress_html(html)
    html.gsub(/[\n\r]+[\s]*/, '')
  end

  def render_govspeak(govspeak, attachments = [], options = {})
    options = options.merge(attachments: attachments)
    Govspeak::Document.new(govspeak, options).to_html
  end

  test "wraps an attachment in a section.attachment.embedded" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2")]
    )
    assert_match(/<section class="attachment embedded">/, rendered)
  end

  test "can convert an attachment with spaces" do
    rendered = render_govspeak(
      "[embed:attachments: 3ed2 ]",
      [build_attachment(content_id: "3ed2")]
    )
    assert_match(/<section class="attachment embedded">/, rendered)
  end

  test "wraps an external attachment in a section.attachment.hosted-externally" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", external?: true)]
    )
    assert_match(/<section class="attachment hosted-externally">/, rendered)
  end

  test "outputs a pub-cover.png thumbnail by default" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2")]
    )
    assert_match(%r{<img src="/images/pub-cover.png"}, rendered)
  end

  test "outputs a specified thumbnail for a pdf with a thumbnail_url" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "pdf", thumbnail_url: "http://a.b/custom.png")]
    )
    assert_match(%r{<img src="http://a.b/custom.png"}, rendered)
  end

  test "outputs pub-cover.png for a pdf without thumbnail_url" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "pdf", thumbnail_url: nil)]
    )
    assert_match(%r{<img src="/images/pub-cover.png"}, rendered)
  end

  test "outputs pub-cover-html.png for a file with html file_extension" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "html")]
    )
    assert_match(%r{<img src="/images/pub-cover-html.png"}, rendered)
  end

  test "outputs pub-cover-doc.png for a file with docx file_extension" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "docx")]
    )
    assert_match(%r{<img src="/images/pub-cover-doc.png"}, rendered)
  end

  test "outputs pub-cover-spreadsheet.png for a file with xls file_extension" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "xls")]
    )
    assert_match(%r{<img src="/images/pub-cover-spreadsheet.png"}, rendered)
  end

  test "outputs no thumbnail for a previewable file" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "csv")]
    )
    assert_match(%r{<div class="attachment-thumb"></div>}, compress_html(rendered))
  end

  test "outputs a title link within a h2" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", id: 1, url: "http://a.b/c.pdf", title: "Attachment Title")]
    )
    assert_match(%r{<h2 class="title">\s*<a href="http://a.b/c.pdf" aria-describedby="attachment-1-accessibility-help">Attachment Title</a></h2>}, compress_html(rendered))
  end

  test "title link has rel='external' for an external link" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", id: 1, url: "http://a.b/c.pdf", external?: true)]
    )
    assert_match(%r{<a href="http://a.b/c.pdf" rel="external" aria-describedby="attachment-1-accessibility-help">}, rendered)
  end

  test "accessible attachment doesn't have the aria-describedby attribute" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", url: "http://a.b/c.pdf", accessible?: true)]
    )
    assert_match(%r{<a href="http://a.b/c.pdf">}, rendered)
  end

  test "outputs reference if isbn is present" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", isbn: "123")]
    )
    assert_match(%r{<span class="references">Ref: ISBN <span class="isbn">123</span></span>}, rendered)
  end

  test "outputs reference if uniuque_reference is present" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", unique_reference: "123")]
    )
    assert_match(%r{<span class="references">Ref: <span class="unique_reference">123</span></span>}, rendered)
  end

  test "outputs reference if command_paper_number is present" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", command_paper_number: "11")]
    )
    assert_match(%r{<span class="references">Ref: <span class="command_paper_number">11</span></span>}, rendered)
  end

  test "outputs reference if hoc_paper_number is present" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", hoc_paper_number: "15", parliamentary_session: "1")]
    )
    assert_match(%r{<span class="references">Ref: <span class="house_of_commons_paper_number">HC 15</span> <span class="parliamentary_session">1</span></span>}, rendered)
  end

  test "can have multiple references" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", isbn: "123", unique_reference: "55")]
    )
    assert_match(%r{<span class="references">Ref: ISBN <span class="isbn">123</span>, <span class="unique_reference">55</span></span>}, rendered)
  end

  test "can show an unnumbered command paper" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", unnumbered_command_paper?: true)]
    )
    assert_match(%r{<span class="unnumbered-paper">\s*Unnumbered command paper\s*</span>}, compress_html(rendered))
  end

  test "can show an unnumbered act paper" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", unnumbered_hoc_paper?: true)]
    )
    assert_match(%r{<span class="unnumbered-paper">\s*Unnumbered act paper\s*</span>}, compress_html(rendered))
  end

  test "unnumbered command paper takes precedence to unnumbered act paper" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", unnumbered_command_paper?: true, unnumbered_hoc_paper?: true)]
    )
    assert_match(%r{<span class="unnumbered-paper">\s*Unnumbered command paper\s*</span>}, compress_html(rendered))
  end

  test "shows a preview link for a previewable format" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "csv", url: "http://a.b/c.csv")]
    )
    assert_match(%r{<span class="preview"><strong>\s*<a href="http://a.b/c.csv/preview">View online</a>\s*</strong></span>}, compress_html(rendered))
  end

  test "Shows a download link for a previewable format" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "csv", url: "http://a.b/c.csv")]
    )
    assert_match(%r{<span class="download">\s*<a href="http://a.b/c.csv"><strong>Download CSV</strong></a>s*</span>}, compress_html(rendered))
  end

  test "Can show filesize for a download link for a previewable format" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "csv", url: "http://a.b/c.csv", file_size: 2048)]
    )
    assert_match(%r{<a href="http://a.b/c.csv" title="2 KB">}, rendered)
  end

  test "for a HTML format it outputs HTML" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", file_extension: "html")]
    )
    assert_match(%r{<span class="type">HTML</span>}, rendered)
  end

  test "for an external type it outputs the url" do
    rendered = render_govspeak(
      "[embed:attachments:3ed2]",
      [build_attachment(content_id: "3ed2", url: "http://a.b/c.pdf", external?: true)]
    )
    assert_match(%r{<span class="url">http://a.b/c.pdf</span>}, rendered)
  end

  test "will show a file extension in a abbr element for non html" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", file_extension: "pdf")]
    )
    assert_match(%r{<span class="type"><abbr title="Portable Document Format">PDF</abbr></span>}, rendered)
  end

  test "will show file size in a span" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", file_size: 1024)]
    )
    assert_match(%r{<span class="file-size">1 KB</span>}, rendered)
  end

  test "will show number of pages" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", number_of_pages: 1)]
    )
    assert_match(%r{<span class="page-length">1 page</span>}, rendered)
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", number_of_pages: 2)]
    )
    assert_match(%r{<span class="page-length">2 pages</span>}, rendered)
  end

  test "can show multiple attributes separated by a comma" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", file_extension: "pdf", file_size: 1024)]
    )
    pdf = %{<span class="type"><abbr title="Portable Document Format">PDF</abbr></span>}
    file_size = %{<span class="file-size">1 KB</span>}
    assert_match(%r{#{pdf}, #{file_size}}, rendered)
  end

  test "can show a link to order a copy of the attachment" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", order_url: "http://a.b/c")]
    )
    assert_match(%r{<a href="http://a.b/c" class="order_url" title="Order a copy of the publication">Order a copy</a>}, rendered)
  end

  test "can not show a link to order a copy of the attachment" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", order_url: "nil")]
    )
    refute_match(%r{<a href="http://a.b/c" class="order_url" title="Order a copy of the publication">Order a copy</a>}, rendered)
  end

  test "can show a price for ordering a copy of the attachment" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", order_url: "http://a.b/c", price: 10)]
    )
    assert_match(%r{(<span class="price">£10.00</span>)}, rendered)
  end

  test "can show opendocument help" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", opendocument?: true)]
    )
    assert_match(%r{<p class="opendocument-help">}, rendered)
  end

  test "can not show opendocument help" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", opendocument?: false)]
    )
    refute_match(%r{<p class="opendocument-help">}, rendered)
  end

  test "can show an accessibility warning" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", id: 10, accessible?: false)]
    )
    assert_match(%r{<div data-module="toggle" class="accessibility-warning" id="attachment-10-accessibility-help">}, rendered)
  end

  test "can not show an accessibility warning" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", id: 10, accessible?: true)]
    )
    refute_match(%r{<div data-module="toggle" class="accessibility-warning" id="attachment-10-accessibility-help">}, rendered)
  end

  test "shows accessibility mailto on a single line" do
    rendered = render_govspeak(
      "[embed:attachments:1fe8]",
      [build_attachment(content_id: "1fe8", id: 10, accessible?: false)]
    )
    assert_match(%r{<a href="mailto:govuk-feedback@digital.cabinet-office.gov.uk\?subject=[^\n]*&amp;body=[^\n]*">govuk-feedback@digital.cabinet-office.gov.uk</a>}, rendered)
  end

  Dir.glob("locales/*.yml") do |filename|
    locale = File.basename(filename, ".yml")
    test "can render in #{locale}" do
      rendered = render_govspeak(
        "[embed:attachments:3ed2]",
        [build_attachment(content_id: "3ed2")],
        locale: locale,
      )
      assert_match(/<section class="attachment embedded">/, rendered)
    end
  end

  test "a full attachment rendering looks correct" do
    attachment = {
      id: 123,
      content_id: "2b4d92f3-f8cd-4284-aaaa-25b3a640d26c",
      title: "Attachment Title",
      url: "http://example.com/test.pdf",
      opendocument?: true,
      order_url: "http://example.com/order",
      price: 12.3,
      isbn: "isbn-123",
      unnumbered_command_paper?: true,
    }
    rendered = render_govspeak(
      "[embed:attachments:2b4d92f3-f8cd-4284-aaaa-25b3a640d26c]",
      [build_attachment(attachment)]
    )
    expected_html_output = %{
      <section class="attachment embedded">
        <div class="attachment-thumb">
          <a href="http://example.com/test.pdf" aria-hidden="true" class="embedded"><img src="/images/pub-cover.png" alt="Pub cover"></a>
        </div>
        <div class="attachment-details">
          <h2 class="title">
            <a href="http://example.com/test.pdf" aria-describedby="attachment-123-accessibility-help">Attachment Title</a>
          </h2>
          <p class="metadata">
            <span class="references">Ref: ISBN <span class="isbn">isbn-123</span></span>
            <span class="unnumbered-paper">
              Unnumbered command paper
            </span>
          </p>
          <p>
            <a href="http://example.com/order" class="order_url" title="Order a copy of the publication">Order a copy</a>(<span class="price">£12.30</span>)
          </p>
          <p class="opendocument-help">
            This file is in an <a rel="external" href="https://en.wikipedia.org/wiki/OpenDocument_software">OpenDocument</a> format
          </p>
          <div data-module="toggle" class="accessibility-warning" id="attachment-123-accessibility-help">
            <h2>This file may not be suitable for users of assistive technology.
              <a class="toggler" href="#attachment-123-accessibility-request" data-controls="attachment-123-accessibility-request" data-expanded="false">Request an accessible format.</a>
            </h2>
            <p id="attachment-123-accessibility-request" class="js-hidden">
              If you use assistive technology (eg a screen reader) and need a
              version of this document in a more accessible format, please email <a href="mailto:govuk-feedback@digital.cabinet-office.gov.uk?subject=Request%20for%20%27Attachment%20Title%27%20in%20an%20alternative%20format&amp;body=Details%20of%20document%20required%3A%0A%0A%20%20Title%3A%20Attachment%20Title%0A%20%20ISBN%3A%20isbn-123%0A%0APlease%20tell%20us%3A%0A%0A%20%201.%20What%20makes%20this%20format%20unsuitable%20for%20you%3F%0A%20%202.%20What%20format%20you%20would%20prefer%3F%0A">govuk-feedback@digital.cabinet-office.gov.uk</a>.
              Please tell us what format you need. It will help us if you say what assistive technology you use.
            </p>
          </div>
        </div>
      </section>
    }
    assert_equal(compress_html(expected_html_output), compress_html(rendered))
  end

  test "attachment that isn't provided" do
    govspeak = "[embed:attachments:906ac8b7-850d-45c6-98e0-9525c680f891]"
    rendered = Govspeak::Document.new(govspeak).to_html
    assert_equal("\n", rendered)
  end

  test "attachment where filename is provided, rather than a content_id" do
    govspeak = "[embed:attachments:/path/to/file%20name.pdf]"
    rendered = Govspeak::Document.new(govspeak).to_html
    assert_equal("\n", rendered)
  end
end
