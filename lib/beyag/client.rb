require 'logger'

module Beyag
  class Client

    GATEWAY_URL = "https://api.bepaid.by/beyag"

    attr_reader :shop_id, :secret_key
    cattr_accessor :proxy

    def initialize(params)
      @shop_id = params.fetch("shop_id")
      @secret_key = params.fetch("secret_key")
    end

    def query(params)
      build_response get("/payments/?id=#{params["id"]}")
    end

    def payment(params)
      build_response post('/payments', request: params)
    end

    private

    attr_reader :response

    def request
      begin
        yield
      rescue Exception => e
        logger = Logger.new(STDOUT)
        logger.error("Request to store ERIP system. Error: #{e.message}\nTrace:\n#{e.backtrace.join("\n")}")
        OpenStruct.new(status: 422)
      end
    end

    def connection
      @connection ||=
        begin
          connection = Faraday.new

          connection.request :json
          connection.headers = {'Content-Type' => 'application/json'}
          connection.basic_auth(shop_id, secret_key)

          connection.proxy(proxy) if proxy

          connection
        end
    end

    def build_response(response)
      Response.new(response)
    end

    def post(path, data = {})
      request { connection.post(GATEWAY_URL << path, data.to_json) }
    end

    def get(path, data = {})
      request { connection.get(GATEWAY_URL << path) }
    end

  end
end