# app/services/parsers/contracts/providers/o2_mobile_parser.rb
module Parsers
  module Contracts
    module Providers
      class O2MobileParser < BaseContractParser
        def mobile? 
          true
        end

        def can_handle?(text)
          !!(text =~ /\bO2\b|\bo2\b|\bTelef[oó]nica\b/i) &&
            (text.include?("Tarif") || text.include?("Rufnummer") || text.include?("Mobilfunk"))
        end

        def extract(text)
          plan_name = text[/\b(?:Tarif|Paket|Vertrag)\s*[:\-]?\s*(o2\s*[^\n]+)/i, 1]&.strip || "O2 Mobile"
          customer_number = text[/\b(?:Kundennummer|Kunden-Nr\.?)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
          contract_number = text[/\b(?:Vertragsnummer|Auftragsnummer)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
          msisdn = text[/\b(?:Rufnummer|Mobilfunknummer|MSISDN)\s*[:\-]?\s*(\+?\d[\d\s\-]+)/i, 1]&.gsub(" ", "")
          start_date = parse_date_de(text[/\b(?:Vertragsbeginn|Beginn|Start)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])
          min_term_months = (text[/\b(?:Mindestvertragslaufzeit|Laufzeit)\s*[:\-]?\s*(\d{1,2})\s*Monat/i, 1] || 24).to_i
          notice_period_days = (text[/\bKündigungsfrist\s*[:\-]?\s*(\d{1,3})\s*Tag/i, 1] || 30).to_i
          monthly_fee = euro(text[/\b(?:Grundgeb[uü]hr|Monatspreis|Paketpreis)\s*[:\-]?\s*([0-9\.,]+)\s*€/i, 1])
          promo_monthly_fee = euro(text[/\b(?:Rabatt|Aktion|Prom[oö])[^\n]*?([0-9\.,]+)\s*€/i, 1])
          promo_end_date = parse_date_de(text[/\b(?:endet|bis)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])

          {
            contract_type: "mobile",
            provider: "O2",
            category: "mobile",
            plan_name: plan_name,
            contract_number: contract_number,
            customer_number: customer_number,
            msisdn: msisdn,
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
