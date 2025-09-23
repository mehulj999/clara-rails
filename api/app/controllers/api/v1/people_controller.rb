# app/controllers/api/v1/people_controller.rb
module Api
  module V1
    class PeopleController < ApplicationController
      before_action :set_person, only: %i[show update destroy]

      def index
        people = current_user.people.order(created_at: :desc)
        render json: people.as_json(only: %i[id name relation dob])
      end

      def show
        render json: @person.as_json(only: %i[id name relation dob])
      end

      def create
        person = current_user.people.build(person_params)
        if person.save
          render json: person, status: :created
        else
          render json: { errors: person.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @person.update(person_params)
          render json: @person
        else
          render json: { errors: @person.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @person.respond_to?(:discard)
          @person.discard
        else
          @person.destroy
        end
        head :no_content
      end

      private

      def set_person
        scope = current_user.people
        scope = scope.kept if scope.respond_to?(:kept)
        @person = scope.find(params[:id])
      end

      def person_params
        params.require(:person).permit(:name, :dob, :relation)
      end
    end
  end
end
