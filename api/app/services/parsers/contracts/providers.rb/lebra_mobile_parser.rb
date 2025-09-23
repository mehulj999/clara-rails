# app/services/parsers/contracts/providers/lebara_mobile_parser.rb
module Parsers
  module Contracts
    module Providers
      class LebaraMobileParser < BaseContractParser
        def mobile?
          true
        end

        def can_handle?(text)
          !!(text =~ /\bLebara\b/i) && (text.include?("Tarif") || text.include?("Rufnummer") || text.include?("Monthly fee"))
        end

        def extract(text)
          plan_name = (text[/\b(?:Tarif|Plan|Paket)\s*[:\-]?\s*(Lebara[^\n]+)/i, 1] || "Lebara Mobile").strip
          customer_number = text[/\b(?:Kundennummer|Customer\s*ID)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
          contract_number = text[/\b(?:Vertragsnummer|Contract\s*No\.?)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
          msisdn = text[/\b(?:Rufnummer|Phone\s*number|MSISDN)\s*[:\-]?\s*(\+?\d[\d\s\-]+)/i, 1]&.gsub(" ", "")
          start_date = parse_date_de(text[/\b(?:Vertragsbeginn|Start\s*date|Beginn)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])
          min_term_months = (text[/\b(?:Mindestvertragslaufzeit|Minimum\s*term)\s*[:\-]?\s*(\d{1,2})\s*Monat/i, 1] || 24).to_i
          notice_period_days = (text[/\b(?:Kündigungsfrist|Notice\s*period)\s*[:\-]?\s*(\d{1,3})\s*Tag/i, 1] || 30).to_i
          monthly_fee = euro(text[/\b(?:Monatspreis|Monthly\s*fee|Grundpreis)\s*[:\-]?\s*([0-9\.,]+)\s*€/i, 1])
          promo_monthly_fee = euro(text[/\b(?:Rabatt|Promo|Aktion)[^\n]*?([0-9\.,]+)\s*€/i, 1])
          promo_end_date = parse_date_de(text[/\b(?:endet|bis|until)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])

          {
            contract_type: "mobile",
            provider: "Lebara",
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
