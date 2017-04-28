class TransactionProcessStateMachine
  include Statesman::Machine

  state :not_started, initial: true
  state :free
  state :initiated
  state :pending  # Deprecated
  state :preauthorized
  state :pending_ext
  state :accepted # Deprecated
  state :rejected
  state :errored
  state :paid
  state :confirmed
  state :canceled

  transition from: :not_started,               to: [:free, :initiated]
  transition from: :initiated,                 to: [:preauthorized]
  transition from: :preauthorized,             to: [:paid, :rejected, :pending_ext, :errored]
  transition from: :pending_ext,               to: [:paid, :rejected]
  transition from: :paid,                      to: [:confirmed, :canceled]

  after_transition(to: :paid) do |transaction|
    payer = transaction.buyer
    current_community = transaction.community
    if transaction.booking.present?
      automatic_booking_confirmation_at = transaction.booking.end_on + 2.day
      ConfirmConversation.new(transaction, payer, current_community).activate_automatic_booking_confirmation_at!(automatic_booking_confirmation_at)
    else
      ConfirmConversation.new(transaction, payer, current_community).activate_automatic_confirmation!
    end
    listing = transaction.listing
    listing.update_fields(status: 'paid')
    Delayed::Job.enqueue(SendPaymentReceipts.new(transaction.id))
  end

  after_transition(to: :rejected) do |transaction|
    rejecter = transaction.listing.provider
    current_community = transaction.community
    listing = transaction.listing
    listing.update_fields(status: 'rejected')
    Delayed::Job.enqueue(TransactionStatusChangedJob.new(transaction.id, rejecter.id, current_community.id))
  end

  after_transition(to: :confirmed) do |conversation|
    listing = conversation.listing
    listing.update_fields({status: 'confirmed', open: false})
    confirmation = ConfirmConversation.new(conversation, conversation.buyer, conversation.community)
    confirmation.confirm!
  end

  after_transition(from: :paid, to: :canceled) do |conversation|
    listing = conversation.listing
    listing.update_fields(status: 'canceled')
    confirmation = ConfirmConversation.new(conversation, conversation.starter, conversation.community)
    confirmation.cancel!
  end

end
