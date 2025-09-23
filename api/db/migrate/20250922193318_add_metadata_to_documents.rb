# db/migrate/20250922120100_add_metadata_to_documents.rb
class AddMetadataToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :sha256, :string
    add_column :documents, :content_type, :string
    add_column :documents, :size_bytes, :bigint
    add_column :documents, :status, :string, default: 'pending', null: false
    add_column :documents, :parser_name, :string
    add_column :documents, :parsed_at, :datetime
    add_column :documents, :parse_error, :text
    add_reference :documents, :uploaded_by, foreign_key: { to_table: :users }, null: true
    add_index :documents, :sha256, unique: true
    add_index :documents, :status
  end
end
