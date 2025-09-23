# app/controllers/api/v1/documents_controller.rb
require 'digest'

class Api::V1::DocumentsController < ApplicationController
  before_action :authenticate_user!  # if using Devise

  def index
    # Scope to current_user via contract->person->user
    docs = Document
      .left_joins(contract: { person: :user })
      .where(users: { id: current_user.id })
      .order(created_at: :desc)
      .limit(50)

    render json: docs.map { |d| serialize(d) }
  end

  def show
    d = find_scoped_document!
    render json: serialize(d)
  end

  def create
    file = params[:file]
    contract_id = params[:contract_id] # optional initial link

    raise ActionController::BadRequest, 'file is required' unless file.respond_to?(:read)

    # Compute sha256 on the uploaded IO (we also capture size and content type)
    io = file.tempfile || file # ActionDispatch::Http::UploadedFile
    sha256 = Digest::SHA256.file(io.path).hexdigest
    size_bytes = File.size(io.path)
    content_type = file.content_type

    # Idempotency: if a doc with same sha exists, just return it
    existing = Document.find_by(sha256: sha256)
    if existing
      return render json: serialize(existing), status: :ok
    end

    doc = Document.new(
      sha256: sha256,
      content_type: content_type,
      size_bytes: size_bytes,
      status: 'pending',
      uploaded_by: current_user,
      contract_id: contract_id
    )

    doc.file.attach(file)

    hints = {
      domain: params[:domain],      # "contract"
      subtype: params[:subtype],    # "mobile" | "internet"
      provider: params[:provider],  # "o2" | "lebara" | "vodafone"
    }
    ActiveRecord::Base.transaction do
      doc.save!
      # Step 4 will enqueue ParseDocumentJob here; for now we only persist.
      # ParseDocumentJob.perform_later(doc.id, hints.symbolize_keys)  # (add once job exists)
    end

    render json: serialize(doc), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: doc&.errors&.full_messages || [e.message] }, status: :unprocessable_entity
  end

  private

  def serialize(d)
    {
      id: d.id,
      sha256: d.sha256,
      status: d.status,
      parser_name: d.parser_name,
      parsed_at: d.parsed_at,
      parse_error: d.parse_error,
      content_type: d.content_type,
      size_bytes: d.size_bytes,
      contract_id: d.contract_id,
      created_at: d.created_at,
    }
  end

  def find_scoped_document!
    Document
      .left_joins(contract: { person: :user })
      .where(users: { id: current_user.id })
      .find(params[:id])
  end
end
