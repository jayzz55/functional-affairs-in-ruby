# SQS -> Worders::PurchaseOrderListner -> 3rd Party Purchasing Platform
#
# Body of SQS message: { "quote_id": "some-quote-id" }
#
# Job: find order by quote_id, then purchase the order
#
# If job is successful, delete the sqs message. Otherwise, do nothing and log error.
# If the order has already been purchased, delete the sqs message and log warning message.

# {{{ Typical ruby code that raise and rescue exceptions all over the place
module Workers
  class PurchaseOrderListener
    include Shoryuken::Worker

    shoryuken_options queue: ENV['ORDER_EVENT_QUEUE'], body_parser: :json

    def perform(sqs_msg, body)
      quote_id = quote_id_from_message(body)

      order = Models::Order.find_by(quote_id: quote_id)

      if order
        Services::PurchaseOrder.from(order.id, {})
        sqs_msg.delete
      else
        err = Errors::ResourceNotFound.new("no matching Order found for quote #{quote_id}")
        raise err
      end
    rescue Errors::OrderAlreadyPurchased => e
      LOGGER.warn(e.message)
      sqs_msg.delete
    rescue => e
      log_error(e)
    end

    private

    def quote_id_from_message(body)
      JSON.parse(body['Message'])['quote_id']
    end

    def log_error(e)
      LOGGER.error [e.message, *e.backtrace].join("\n")
    end
  end
end
#}}}

###############################################################3

#{{{ Refactoring with Dry::Monads
module Workers
  class PurchaseOrderListener
    include Shoryuken::Worker
    extend Dry::Monads::Try::Mixin
    M = Dry::Monads

    shoryuken_options queue: ENV['ORDER_EVENT_QUEUE'], body_parser: :json

    def perform(sqs_msg, body)
      quote_id = quote_id_from_message(body)

      purchased_order = get_order_by(quote_id).bind { |order| purchase(order) }

      if purchased_order.success?
        sqs_msg.delete
      else
        log_error(error)
      end
    end

    private

    def quote_id_from_message(body)
      JSON.parse(body['Message'])['quote_id']
    end

    def get_order_by(quote_id)
      order = Models::Order.find_by(quote_id: quote_id)
      if order
        M.Success(order)
      else
        M.Failure(Errors::ResourceNotFound.new("no matching deal proposal found for quote #{quote_id}"))
      end
    end

    def purchase(order)
      Services::PurchaseOrder.from(order.id, {})
      M.Success(nil)
    rescue Errors::OrderAlreadyPurchased => e
      LOGGER.warn(e.message)
      M.Success(nil)
    rescue => e
      M.Failure(e)
    end

    def log_error(e)
      LOGGER.error [e.message, *e.backtrace].join("\n")
    end
  end
end
#}}}
