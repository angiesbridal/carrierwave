require 'open-uri'
require 'addressable'
require 'carrierwave/downloader/remote_file'

module CarrierWave
  module Downloader
    class Base
      attr_reader :uploader

      def initialize(uploader)
        @uploader = uploader
      end

      ##
      # Downloads a file from given URL and returns a RemoteFile.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      # [remote_headers (Hash)] Request headers
      #
      def download(url, remote_headers = {})
        headers = remote_headers.
          reverse_merge('User-Agent' => "CarrierWave/#{CarrierWave::VERSION}")
        begin
          file = OpenURI.open_uri(process_uri(url.to_s), headers)
        rescue StandardError => e
          raise CarrierWave::DownloadError, "could not download file: #{e.message}"
        end
        CarrierWave::Downloader::RemoteFile.new(file)
      end

      ##
      # Processes the given URL by parsing and escaping it. Public to allow overriding.
      #
      # === Parameters
      #
      # [url (String)] The URL where the remote file is stored
      #
      def process_uri(uri)
        uri_parts = uri.split('?')
        encoded_uri = Addressable::URI.parse(uri_parts.shift).normalize.to_s
        query = uri_parts.join('?').split(':').map { |part| Addressable::URI.encode(part) }.join(':') if uri_parts.any?
        encoded_uri << '?' << query.gsub('%5B', '[').gsub('%5D', ']') if query
        URI.parse(encoded_uri)
      rescue URI::InvalidURIError, Addressable::URI::InvalidURIError
        raise CarrierWave::DownloadError, "couldn't parse URL: #{uri}"
      end
    end
  end
end
