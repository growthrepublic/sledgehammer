class Sledgehammer::CrawlWorker
  include ::Sidekiq::Worker
  MAIL_REGEX = /[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/
  URL_REGEX  = /<a\s+(?:[^>]*?\s+)?href="((?:http|\/)[^"]+)"/

  def perform(urls, depth = 0, depth_limit = 3)
    @depth       = depth
    @depth_limit = depth_limit

    urls.each { |site| self.queue(site) }
    run_queue
  end

  def queue(site)
    request = Typhoeus::Request.new(site)
    request.on_complete do |response|
      page = self.find_or_create_page!(response)
      self.parse_emails(response, page)
      self.parse_urls(response)
    end

    Typhoeus::Hydra.hydra.queue(request)
  end

  def run_queue
    Typhoeus::Hydra.hydra.run
  end

  protected
  def find_or_create_page!(response)
    request_url = response.request.url
    page = Sledgehammer::Page.find_by(url: request_url)

    unless page
      hostname = URI.parse(request_url).host
      website  = Sledgehammer::Website.find_or_create_by(hostname: hostname)
      page = Sledgehammer::Page.create!(url: request_url, depth: @depth)
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
      if (url == '/' || url == request_url)
        return
      elsif url.starts_with?('/')
        URI.join(request_url, url).to_s
      else
        url
      end
    end.compact

    unless @depth + 1 >= @depth_limit || url_list.empty?
      self.class.perform_async(url_list, @depth + 1, @depth_limit)
    end
  end
end
