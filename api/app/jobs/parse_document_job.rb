# app/jobs/parse_document_job.rb
class ParseDocumentJob < ApplicationJob
  queue_as :default

  def perform(document_id, hints = {})
    doc = Document.find(document_id)

    doc.file.open(tmpdir: Dir.tmpdir) do |file_io|
      res = DocumentParser.parse(file_io.path, hints: hints)

      if res.kind == :contract
        ActiveRecord::Base.transaction do
          raise "Document not linked to a contract_id" if doc.contract_id.blank?
          contract = Contract.find(doc.contract_id)

          # merge (fill blanks only)
          merged = merge_contract_attrs(contract, res.attrs)
          contract.update!(merged)

          doc.update!(status: "parsed", parser_name: res.parser_name, parsed_at: Time.current)
        end
      else
        doc.update!(status: "failed", parse_error: "No suitable parser")
      end
    end
  rescue => e
    doc.update!(status: "failed", parse_error: e.message) if doc&.persisted?
  end

  private

  def merge_contract_attrs(contract, attrs)
    keep = contract.attributes.symbolize_keys.slice(
      :contract_type, :provider, :category, :plan_name, :contract_number, :customer_number,
      :msisdn, :start_date, :end_date, :min_term_months, :notice_period_days,
      :monthly_fee, :promo_monthly_fee, :promo_end_date, :currency,
      :termination_email, :termination_address, :notes
    )
    attrs.each { |k, v| keep[k] = v if keep[k].blank? && !v.nil? }
    keep
  end
end
