# app/services/parsers/contracts/registry.rb
module Parsers
  module Contracts
    class Registry
      # Register providers here
      PROVIDER_CLASSES = {
        "o2"       => "Parsers::Contracts::Providers::O2MobileParser",
        "lebara"   => "Parsers::Contracts::Providers::LebaraMobileParser",
        "vodafone" => "Parsers::Contracts::Providers::VodafoneInternetParser",
      }.freeze

      # Parse with hints or auto-detect
      def self.parse(io_or_path, hints: {})
        text = nil

        # 1) If provider hint present, try that first
        if (prov = hints[:provider]&.to_s&.downcase)&.present?
          klass_name = PROVIDER_CLASSES[prov]
          if klass_name
            parser = klass_name.constantize.new
            text ||= parser.extract_text(io_or_path)
            return { parser_name: parser.class.name.demodulize.underscore, attrs: parser.extract(text) } if parser.can_handle?(text)
          end
        end

        # 2) If subtype hint present, narrow candidate list (optional)
        subtype = hints[:subtype]&.to_s

        candidates = PROVIDER_CLASSES.values.map(&:constantize).map(&:new)
        candidates.select! { |p| subtype == "mobile" ? p.respond_to?(:mobile?) && p.mobile? : true } if subtype

        # 3) Auto-detect by can_handle?
        text ||= candidates.first&.extract_text(io_or_path) || Parsers::Contracts::BaseContractParser.new.extract_text(io_or_path)
        candidates.each do |parser|
          return { parser_name: parser.class.name.demodulize.underscore, attrs: parser.extract(text) } if parser.can_handle?(text)
        end

        nil
      end
    end
  end
end
