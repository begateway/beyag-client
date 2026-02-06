module Beyag
  class Response
    class Error
      def initialize(error)
        @error = error
      end

      def successful?
        false
      end

      def message
        @error.message
      end

      def errors
        { 'error' => message }
      end

      def bank_code
        'P.9999'
      end

      def data
        { 'status' => 'error', 'message' => message, 'bank_code' => bank_code, 'errors' => errors }
      end

      %i[id service_no transaction payment_method status].each do |name|
        define_method(name) {}
      end
    end

    attr_reader :response, :data

    def initialize(response)
      @response = response
      @data = begin
                JSON.parse(response.body)
              rescue JSON::ParserError
                {}
              end
    end

    def id
      transaction && (transaction["id"] || transaction["uid"])
    end

    def service_no
      transaction["erip"]["service_no"]
    end

    def transaction
      data["transaction"]
    end

    def payment_method
      if transaction && (pm = transaction["payment_method_type"] || transaction["method_type"])
        transaction[pm]
      else
        {}
      end
    end

    def successful?
      (200..299).include?(status)
    end

    def error?
      !!errors
    end

    def message
      data["message"] || transaction["message"]
    end

    def errors
      data["errors"]
    end

    def status
      response.status.to_i
    end

    def status_url
      data['status_url']
    end

    def response_url
      data['response_url']
    end

    def request_id
      data['request_id']
    end
  end
end
