class Sledgehammer::CrawlWorker
  include ::Sidekiq::Worker
  MAIL_REGEX = /[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/
  URL_REGEX  = /<a\s+(?:[^>]*?\s+)?href="((?:http|\/)[^"]+)"/

  def perform(urls, depth = 0, depth_limit = 3)
    unless depth >= depth_limit
      @depth       = depth
      @depth_limit = depth_limit

      urls.each { |site| self.queue(site) }
      run_queue
    end
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

      Sledgehammer::Page.create!(url: request_url, depth: @depth)
    end
  end

  def parse_emails(response, page)
    mail_list = response.body.scan MAIL_REGEX
    mail_list.each { |mail| Sledgehammer::Contact.create!(email: mail, page: page) }
  end

  # TODO: remove url == '/' because we not always start at root page
  def parse_urls(response)
    request_url = response.request.url
    url_list = response.body.scan(URL_REGEX).flatten.map do |url|
      if (url == '/' || url == request_url)
        return
      elsif url.starts_with?('/')
        URI.join(request_url, url).to_s
      else
        url
      end
    end.compact

    self.class.perform_async(url_list, @depth + 1, @depth_limit) unless url_list.empty?
  end
end
