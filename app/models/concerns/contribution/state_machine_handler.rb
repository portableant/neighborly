module Contribution::StateMachineHandler
  extend ActiveSupport::Concern

  included do
    state_machine :state, initial: :pending do
      state :pending
      state :waiting_confirmation
      state :confirmed
      state :canceled
      state :refunded
      state :requested_refund
      state :refunded_and_canceled
      state :deleted

      event :push_to_trash do
        transition all => :deleted
      end

      event :pendent do
        transition all => :pending
      end

      event :wait_confirmation do
        transition pending: :waiting_confirmation
      end

      event :confirm do
        transition all => :confirmed
      end

      event :cancel do
        transition all => :canceled
      end

      event :request_refund do
        transition confirmed: :requested_refund, if: ->(contribution){
          contribution.user.credits >= contribution.value && !contribution.credits
        }
      end

      event :refund do
        transition [:requested_refund, :confirmed] => :refunded
      end

      event :hide do
        transition all => :refunded_and_canceled
      end

      after_transition confirmed: :requested_refund, do: :after_transition_from_confirmed_to_requested_refund
      after_transition confirmed: :canceled, do: :after_transition_from_confirmed_to_canceled
    end

    def after_transition_from_confirmed_to_canceled
      notify_observers :notify_backoffice_about_canceled
    end

    def after_transition_from_confirmed_to_requested_refund
      notify_observers :notify_backoffice
    end
  end
end
