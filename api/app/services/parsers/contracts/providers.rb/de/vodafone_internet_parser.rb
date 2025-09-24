# app/services/parsers/contracts/providers/vodafone_internet_parser.rb
module Parsers
  module Contracts
    module Providers
      class VodafoneInternetParser < BaseContractParser
        def mobile?  
          false
        end

        def can_handle?(text)
          !!(text =~ /\bVodafone\b/i) && (text.include?("Cable") || text.include?("DSL") || text.include?("GigaZuhause"))
        end

        def extract(text)
          plan_capture = text[/\b(?:Tarif|Produkt|Paket)\s*[:\-]?\s*(GigaZuhause|Red Internet|Vodafone Cable|DSL|Fiber|Station|Cable)\s*([^\n]*)/i]
          plan_name = if plan_capture
            plan_capture.scan(/(GigaZuhause|Red Internet|Vodafone Cable|DSL|Fiber|Station|Cable)\s*([^\n]*)/i).flatten.join(" ").strip
          end

          customer_number = text[/\b(?:Kundennummer|Kunden-Nr\.?)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
          contract_number = text[/\b(?:Vertragsnummer|Auftragsnummer)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
          start_date = parse_date_de(text[/\b(?:Vertragsbeginn|Beginn|Start)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])
          min_term_months = (text[/\b(?:Laufzeit|Mindestvertragslaufzeit)\s*[:\-]?\s*(\d{1,2})\s*Monat/i, 1] || 24).to_i
          notice_period_days = (text[/\bKündigungsfrist\s*[:\-]?\s*(\d{1,3})\s*Tag/i, 1] || 90).to_i
          monthly_fee = euro(text[/\b(?:Monatspreis|Grundpreis)\s*[:\-]?\s*([0-9\.,]+)\s*€/i, 1])
          promo_monthly_fee = euro(text[/\b(?:Rabatt|Aktion|Promo)[^\n]*?([0-9\.,]+)\s*€/i, 1])
          promo_end_date = parse_date_de(text[/\b(?:endet|bis)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])

          {
            contract_type: "internet",
            provider: "Vodafone",
            category: "internet",
            plan_name: plan_name || "Vodafone Internet",
            contract_number: contract_number,
            customer_number: customer_number,
            msisdn: nil,
            start_date: start_date,
            end_date: nil,
            min_term_months: min_term_months,
            notice_period_days: notice_period_days,
            monthly_fee: monthly_fee,
            promo_monthly_fee: promo_monthly_fee,
            promo_end_date: promo_end_date,
            currency: "EUR"
          }
        end
      end
    end
  end
end
