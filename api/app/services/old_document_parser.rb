# app/services/document_parser.rb
require "pdf/reader"
require "date"

class DocumentParser
  # Result struct
  Parsed = Struct.new(:kind, :parser_name, :attrs, keyword_init: true)
  # kind: :contract | :unknown
  # parser_name: e.g., "o2_mobile"
  # attrs: Hash of contract fields matching your Contract columns

  # ---- helpers (DE dates, euro) ---------------------------------------------
  def self.parse_date_de(str)
    return nil if str.nil?
    s = str.to_s.strip
    if (m = s.match(/\b(\d{2}\.\d{2}\.\d{4})\b/))
      Date.strptime(m[1], "%d.%m.%Y") rescue nil
    elsif (m = s.match(/\b(\d{4}-\d{2}-\d{2})\b/))
      Date.strptime(m[1], "%Y-%m-%d") rescue nil
    else
      nil
    end
  end

  def self.euro(str)
    return nil if str.nil?
    s = str.to_s.gsub("€", "").gsub(" ", "").gsub(".", "").gsub(",", ".")
    Float(s)
  rescue
    nil
  end

  # ---- text extraction -------------------------------------------------------
  def self.extract_text(io_or_path)
    text = +""
    PDF::Reader.new(io_or_path).pages.each do |page|
      text << "\n" << (page.text || "")
    end
    text
  end

  # ---- CONTRACT PARSERS (single file, table-driven) -------------------------
  CONTRACT_PARSERS = [
    {
      name: "o2_mobile",
      can_handle: ->(t) {
        !!(t =~ /\bO2\b|\bo2\b|\bTelef[oó]nica\b/i) &&
        (t.include?("Tarif") || t.include?("Rufnummer") || t.include?("Mobilfunk"))
      },
      extract: ->(t) {
        plan_name = t[/\b(?:Tarif|Paket|Vertrag)\s*[:\-]?\s*(o2\s*[^\n]+)/i, 1]&.strip || "O2 Mobile"
        customer_number = t[/\b(?:Kundennummer|Kunden-Nr\.?)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
        contract_number = t[/\b(?:Vertragsnummer|Auftragsnummer)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
        msisdn = t[/\b(?:Rufnummer|Mobilfunknummer|MSISDN)\s*[:\-]?\s*(\+?\d[\d\s\-]+)/i, 1]&.gsub(" ", "")
        start_date = DocumentParser.parse_date_de(t[/\b(?:Vertragsbeginn|Beginn|Start)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])
        min_term_months = (t[/\b(?:Mindestvertragslaufzeit|Laufzeit)\s*[:\-]?\s*(\d{1,2})\s*Monat/i, 1] || 24).to_i
        notice_period_days = (t[/\bKündigungsfrist\s*[:\-]?\s*(\d{1,3})\s*Tag/i, 1] || 30).to_i
        monthly_fee = DocumentParser.euro(t[/\b(?:Grundgeb[uü]hr|Monatspreis|Paketpreis)\s*[:\-]?\s*([0-9\.,]+)\s*€/i, 1])
        promo_monthly_fee = DocumentParser.euro(t[/\b(?:Rabatt|Aktion|Prom[oö])[^\n]*?([0-9\.,]+)\s*€/i, 1])
        promo_end_date = DocumentParser.parse_date_de(t[/\b(?:endet|bis)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])

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
      }
    },
    {
      name: "lebara_mobile",
      can_handle: ->(t) {
        !!(t =~ /\bLebara\b/i) && (t.include?("Tarif") || t.include?("Rufnummer") || t.include?("Monthly fee"))
      },
      extract: ->(t) {
        plan_name = (t[/\b(?:Tarif|Plan|Paket)\s*[:\-]?\s*(Lebara[^\n]+)/i, 1] || "Lebara Mobile").strip
        customer_number = t[/\b(?:Kundennummer|Customer\s*ID)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
        contract_number = t[/\b(?:Vertragsnummer|Contract\s*No\.?)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
        msisdn = t[/\b(?:Rufnummer|Phone\s*number|MSISDN)\s*[:\-]?\s*(\+?\d[\d\s\-]+)/i, 1]&.gsub(" ", "")
        start_date = DocumentParser.parse_date_de(t[/\b(?:Vertragsbeginn|Start\s*date|Beginn)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])
        min_term_months = (t[/\b(?:Mindestvertragslaufzeit|Minimum\s*term)\s*[:\-]?\s*(\d{1,2})\s*Monat/i, 1] || 24).to_i
        notice_period_days = (t[/\b(?:Kündigungsfrist|Notice\s*period)\s*[:\-]?\s*(\d{1,3})\s*Tag/i, 1] || 30).to_i
        monthly_fee = DocumentParser.euro(t[/\b(?:Monatspreis|Monthly\s*fee|Grundpreis)\s*[:\-]?\s*([0-9\.,]+)\s*€/i, 1])
        promo_monthly_fee = DocumentParser.euro(t[/\b(?:Rabatt|Promo|Aktion)[^\n]*?([0-9\.,]+)\s*€/i, 1])
        promo_end_date = DocumentParser.parse_date_de(t[/\b(?:endet|bis|until)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])

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
      }
    },
    {
      name: "vodafone_internet",
      can_handle: ->(t) {
        !!(t =~ /\bVodafone\b/i) && (t.include?("Cable") || t.include?("DSL") || t.include?("GigaZuhause"))
      },
      extract: ->(t) {
        plan_capture = t[/\b(?:Tarif|Produkt|Paket)\s*[:\-]?\s*(GigaZuhause|Red Internet|Vodafone Cable|DSL|Fiber|Station|Cable)\s*([^\n]*)/i]
        plan_name = if plan_capture
          # full match contains two captures after the prelude; rebuild name
          captures = plan_capture.scan(/(GigaZuhause|Red Internet|Vodafone Cable|DSL|Fiber|Station|Cable)\s*([^\n]*)/i).flatten
          captures.join(" ").strip
        end
        customer_number = t[/\b(?:Kundennummer|Kunden-Nr\.?)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
        contract_number = t[/\b(?:Vertragsnummer|Auftragsnummer)\s*[:\-]?\s*([A-Z0-9\-\.]+)/i, 1]
        start_date = DocumentParser.parse_date_de(t[/\b(?:Vertragsbeginn|Beginn|Start)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])
        min_term_months = (t[/\b(?:Laufzeit|Mindestvertragslaufzeit)\s*[:\-]?\s*(\d{1,2})\s*Monat/i, 1] || 24).to_i
        notice_period_days = (t[/\bKündigungsfrist\s*[:\-]?\s*(\d{1,3})\s*Tag/i, 1] || 90).to_i
        monthly_fee = DocumentParser.euro(t[/\b(?:Monatspreis|Grundpreis)\s*[:\-]?\s*([0-9\.,]+)\s*€/i, 1])
        promo_monthly_fee = DocumentParser.euro(t[/\b(?:Rabatt|Aktion|Promo)[^\n]*?([0-9\.,]+)\s*€/i, 1])
        promo_end_date = DocumentParser.parse_date_de(t[/\b(?:endet|bis)\s*[:\-]?\s*([0-9\.\-]{8,10})/i, 1])

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
      }
    }
  ].freeze

  # ---- public API ------------------------------------------------------------
  def self.parse_contract_from_pdf(io_or_path)
    text = extract_text(io_or_path)
    parser = CONTRACT_PARSERS.find { |p| p[:can_handle].call(text) }
    return Parsed.new(kind: :unknown, parser_name: nil, attrs: {}) unless parser

    attrs = parser[:extract].call(text)
    Parsed.new(kind: :contract, parser_name: parser[:name], attrs: attrs)
  end
end
