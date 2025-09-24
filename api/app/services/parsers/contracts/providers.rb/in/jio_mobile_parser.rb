# app/services/parsers/contracts/providers/in/jio_mobile_parser.rb
module Parsers
  module Contracts
    module Providers
      module IN
        class JioMobileParser < BaseContractParser
          def can_handle?(text)
            text =~ /\bJio\b/i
          end

          def extract(text, country: "IN")
            attrs = {
              contract_type: "mobile",
              provider: "Jio",
              category: "mobile",
              plan_name: text[/Plan\s*:\s*([^\n]+)/i, 1],
              contract_number: nil,
              customer_number: text[/Customer\s*ID\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1],
              msisdn: text[/\b(?:MSISDN|Phone|Rufnummer)\s*[:\-]?\s*(\+?\d[\d\s\-]+)/i, 1]&.gsub(" ", ""),
              start_date: parse_date_de(text),
              end_date: nil,
              min_term_months: 12,
              notice_period_days: 30,
              monthly_fee: euro(text[/Monthly\s*fee\s*[:\-]?\s*([0-9\.,]+)\s*(?:₹|INR)?/i, 1]),
              promo_monthly_fee: nil,
              promo_end_date: nil,
              currency: nil
            }
            merge_defaults(attrs, country)
          end
        end
      end
    end
  end
end
