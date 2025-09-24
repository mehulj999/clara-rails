# app/services/parsers/contracts/base_contract_parser.rb
require "pdf/reader"

module Parsers
  module Contracts
    class BaseContractParser < ::Parsers::Base
      def parse_date_de(str)
        return nil if str.nil?
        s = str.to_s.strip
        if (m = s.match(/\b(\d{2}\.\d{2}\.\d{4})\b/))
          Date.strptime(m[1], "%d.%m.%Y") rescue nil
        elsif (m = s.match(/\b(\d{4}-\d{2}-\d{2})\b/))
          Date.strptime(m[1], "%Y-%m-%d") rescue nil
        end
      end

      def euro(str)
        return nil if str.nil?
        s = str.to_s.gsub("€", "").gsub(" ", "").gsub(".", "").gsub(",", ".")
        Float(s)
      rescue
        nil
      end

      def extract_text(io_or_path)
        text = +""
        PDF::Reader.new(io_or_path).pages.each { |p| text << "\n" << (p.text || "") }
        text
      end

      # Helper to merge country defaults into the final attrs
      def merge_defaults(attrs, country)
        defaults = case country
                   when "IN" then { currency: "INR" }
                   else           { currency: "EUR" }
                   end
        defaults.merge(attrs){ |_k, v1, v2| v2 || v1 }
      end
    end
  end
end
