# app/services/parsers/contracts/registry.rb
module Parsers
  module Contracts
    class Registry
      # Map country -> array of provider classes
      COUNTRY_PROVIDERS = {
        "DE" => [
          "Parsers::Contracts::Providers::DE::O2MobileParser",
          "Parsers::Contracts::Providers::DE::LebaraMobileParser",
          "Parsers::Contracts::Providers::DE::VodafoneInternetParser",
        ],
        "IN" => [
          # Stubs you can add later
          "Parsers::Contracts::Providers::IN::JioMobileParser",
          "Parsers::Contracts::Providers::IN::AirtelMobileParser",
        ]
      }.freeze

      # Optional aliases like "Germany" -> "DE"
      COUNTRY_ALIAS = {
        "GERMANY" => "DE", "DE" => "DE",
        "INDIA"   => "IN", "IN" => "IN"
      }.freeze

      def self.normalize_country(c)
        return nil if c.blank?
        COUNTRY_ALIAS[c.to_s.upcase] || c.to_s.upcase
      end

      def self.parse(io_or_path, hints: {})
        # Resolve country precedence: hints -> document/contract (caller supplies) -> default
        country = normalize_country(hints[:country]) || "DE"
        providers = (COUNTRY_PROVIDERS[country] || []).map { _1.constantize.new }

        # If provider hint exists, prioritize that one
        if (prov = hints[:provider].to_s.downcase.presence)
          candidates = providers.select { |p| p.class.name.demodulize.underscore.include?(prov) }
          providers = (candidates + (providers - candidates)).uniq
        end

        text = nil
        providers.each do |parser|
          text ||= parser.extract_text(io_or_path)
          return { parser_name: parser.class.name.demodulize.underscore, attrs: parser.extract(text.merge_country_defaults(country)) } if parser.can_handle?(text)
        end

        nil
      end
    end
  end
end
