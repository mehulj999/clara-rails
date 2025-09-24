# api/app/controllers/api/v1/contracts_controller.rb
module Api
  module V1
    class ContractsController < ApplicationController
      before_action :set_contract, only: %i[show update destroy]

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not found" }, status: :not_found
      end

      def index
        per_page = [params[:per_page].presence&.to_i || 20, 100].min

        records = Contract.kept
                          .includes(:person)
                          .joins(:person)
                          .where(people: { user_id: current_user.id })
                          .order(created_at: :desc)

        pagy_obj, page = pagy(records, items: per_page)
        render json: {
          data: page.as_json(
            include: { person: { only: %i[id name relation] } },
            except: %i[discarded_at]
          ),
          pagy: pagy_metadata(pagy_obj)
        }
      end

      def show
        render json: @contract.as_json(
          include: { person: { only: %i[id name relation] } },
          except: %i[discarded_at]
        )
      end

      def create
        # person_id is required and must belong to current_user
        pid = contract_params[:person_id]
        return render json: { errors: ["person_id is required"] }, status: :unprocessable_entity if pid.blank?

        person = current_user.people.find(pid)

        contract = Contract.new(contract_params.except(:person_id))
        contract.person = person

        if contract.save
          render json: contract, status: :created
        else
          render json: { errors: contract.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        # If switching person, ensure it belongs to current_user
        if params.dig(:contract, :person_id).present?
          person = current_user.people.find(params[:contract][:person_id])
          @contract.person = person
        end

        if @contract.update(contract_params.except(:person_id))
          render json: @contract
        else
          render json: { errors: @contract.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @contract.discard
        head :no_content
      end

      private

      def set_contract
        # Only find contracts whose person belongs to current_user
        @contract = Contract.kept
                            .includes(:person)
                            .joins(:person)
                            .where(people: { user_id: current_user.id })
                            .find(params[:id])
      end

      def contract_params
        params.require(:contract).permit(
          :contract_type, :provider, :category, :plan_name, :contract_number, :customer_number,
          :msisdn, :start_date, :end_date, :min_term_months, :notice_period_days,
          :monthly_fee, :promo_monthly_fee, :promo_end_date, :currency,
          :termination_email, :termination_address, :notes, :person_id,
          :country_code 
        )
      end
    end
  end
end
