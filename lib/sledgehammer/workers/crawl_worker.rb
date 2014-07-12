class Sledgehammer::CrawlWorker
  include ::Sidekiq::Worker
  MAIL_REGEX = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.(?!jpg|gif|png)[A-Z0-9]+/i
  URL_REGEX  = /<a\s+(?:[^>]*?\s+)?href="((?:http|\/)[^"]+)"/
  DEFAULT_OPTIONS = { depth: 0, depth_limit: 1, queue: 'default' }

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

  def on_complete(response)
    page = self.find_or_create_page!(response.request.url)
    unless page.completed?
      self.parse_emails(response, page)
      self.parse_urls(response)
      page.update_attributes completed: true
    end
  end

  #
  # There shouldn't be any need to overload methods below
  #

  def perform(urls, opts = {})
    @options = HashWithIndifferentAccess.new(DEFAULT_OPTIONS)
    @options.merge!(opts)

    return if @options[:depth] == @options[:depth_limit]

    before_queue(urls)
    urls.each { |site| self.queue(site) }
    run_queue
    after_queue(urls)
  end

  def queue(url)
    return unless self.on_queue(url) && valid_url?(url)

    request = Typhoeus::Request.new(url)
    request.on_complete { |response| self.on_complete(response) }

    Typhoeus::Hydra.hydra.queue(request)
  end

  def run_queue
    Typhoeus::Hydra.hydra.run
  end

  protected
  def find_or_create_page!(request_url)
    page = Sledgehammer::Page.find_by(url: request_url)

    if page.blank?
      hostname = URI.parse(request_url).host
      website  = Sledgehammer::Website.find_or_create_by(hostname: hostname)
      page     = Sledgehammer::Page.create!(url: request_url, depth: @options[:depth], website: website)
    elsif page.depth < @options[:depth]
      page.update_attributes completed: false
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

  def parse_urls(response)
    request_url = response.request.url
    request_url = "http://#{request_url}" unless request_url.match /^http/

    url_list = scan_for_urls(response.body).map do |url|
      (url == request_url || !valid_url?(url)) ? nil : absolute_url(request_url, url)
    end.compact

    go_deeper url_list
  end

  def valid_url?(url)
    !!URI.parse(url) rescue false
  end

  def absolute_url(request_url, url)
    url = URI.join(request_url, url).to_s if url.starts_with?('/')
    url
  end

  def scan_for_urls(body)
    body.scan(URL_REGEX).flatten
  end

  def go_deeper(url_list)
    opts         = @options.dup
    opts[:depth] += 1

    unless opts[:depth] >= opts[:depth_limit] || url_list.empty?
      Sidekiq::Client.push('queue' => opts[:queue],
                           'class' => self.class,
                           'args' => [url_list, opts])
    end
  end
end
