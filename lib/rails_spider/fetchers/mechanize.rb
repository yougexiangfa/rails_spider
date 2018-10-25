require 'mechanize'
require 'rails_spider/fetchers/base'

module RailsSpider
  class Mechanize < Fetcher
    attr_accessor :mechanize, :logger

    def initialize
      super
      @mechanize = ::Mechanize.new
      @mechanize.open_timeout = 20
      @mechanize.pluggable_parser.default = @mechanize.pluggable_parser['text/html']
      @logger = Logger.new STDOUT
    end

    def page(url)
      mechanize.get(url)
    end

    def body(url)
      page(url).search('body')
    end

    def links(url)
      page(url).links.map do |link|
        begin
          link.resolved_uri.to_s
        rescue ::Mechanize::UnsupportedSchemeError
          ''
        end
      end
    end

    def change_another_proxy(proxy_hash=nil, header_hash=nil)
      if proxy_hash && proxy_hash[:ip] && proxy_hash[:port]
        ip = proxy_hash[:ip]
        port = proxy_hash[:port]
      else
        index = rand(@proxy.size)
        ip = @proxy[index][:ip]
        port = @proxy[index][:port]
      end
      @mechanize.set_proxy ip, port

      @mechanize.request_headers = header_hash unless header_hash.nil?
    end

    def is_grab?(url)
      event_class.where(url: url).exists?
    end

    def run
      logger.info "Start #{self.class} Spider..."

      @links.each do |link|
        #@city = link.values.first
        grab_list_link(link.keys.first)
      end

      logger.info "End of #{self.class} Spider..."
    end

    def grab_update
      logger.info "Start #{self.class} Spider grab_update."

      @newlinks.each do |link|
        @city = link['city'] unless link['city'].blank?
        grab_list_link(link['url'])
      end

      logger.info "End of #{self.class} Spider grab_update."
    end

    def is_existed?(event_hash)
      if event_hash[:url] && event = event_class.where(url: event_hash[:url]).first
        logger.warn "#{event_hash[:url]} has been exist in #{event.id}"
        return true
      end
      return false
    end

  end
end