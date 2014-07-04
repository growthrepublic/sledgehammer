class Sledgehammer::CrawlWorker
  include ::Sidekiq::Worker
  MAIL_REGEX = /[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/
  URL_REGEX  = /<a\s+(?:[^>]*?\s+)?href="((?:http|\/)[^"]+)"/

  # TODO: Next time you want to add a new callback, refactor this to use https://github.com/apotonick/hooks

  #
  # Callbacks to overload in application
  #
  def before_queue(urls)
    # stub
  end

  #
  # Stops element from being added to queue if returns false
  #
  def on_queue(url)
    true
  end

  def after_queue(urls)
    # stub
  end

  def on_headers(response)
    # stub
  end

  def on_body(response)
    # stub
  end

  def on_complete(response)
    page = self.find_or_create_page!(response.request.url)

    self.parse_emails(response, page)
    self.parse_urls(response)
    page.update_attribute :completed, true
  end

  def perform(urls, opts={})
    @depth       = opts[:depth] || 0
    @depth_limit = opts[:depth_limit] || 1

    return if @depth == @depth_limit

    before_queue(urls)
    urls.each { |site| self.queue(site) }
    run_queue
    after_queue(urls)
  end

  def queue(url)
    return unless self.on_queue(url) && valid_url?(url)

    request = Typhoeus::Request.new(url)
    request.on_headers  { |response| self.on_headers(response) }
    request.on_body     { |response| self.on_body(response) }
    request.on_complete { |response| self.on_complete(response) }

    Typhoeus::Hydra.hydra.queue(request)
  end

  def run_queue
    Typhoeus::Hydra.hydra.run
  end

  protected
  def find_or_create_page!(request_url)
    page = Sledgehammer::Page.find_by(url: request_url)

    unless page
      hostname = URI.parse(request_url).host
      website  = Sledgehammer::Website.find_or_create_by(hostname: hostname)
      page = Sledgehammer::Page.create!(url: request_url, depth: @depth, website: website)
    end
    page
  end

  def parse_emails(response, page)
    mail_list = response.body.scan MAIL_REGEX
    mail_list.each do |email|
      contact = Sledgehammer::Contact.find_or_create_by(email: email)
      Sledgehammer::PageContact.find_or_create_by page: page, contact: contact
    end
  end

  # TODO: remove url == '/' because we not always start at root page
  def parse_urls(response)
    request_url = response.request.url
    request_url = "http://#{request_url}" unless request_url.match /^http/
    url_list = response.body.scan(URL_REGEX).flatten.map do |url|
      if url == request_url
        return
      elsif url.starts_with?('/')
        URI.join(request_url, url).to_s
      elsif valid_url?(url)
        url
      end
    end.compact

    depth = @depth + 1
    unless depth >= @depth_limit || url_list.empty?
      self.class.perform_async(url_list, { depth: depth, depth_limit: @depth_limit })
    end
  end

  def valid_url?(url)
    !!URI.parse(url) rescue false
  end


end
