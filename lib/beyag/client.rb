require 'logger'
require 'ostruct'

module Beyag
  class Client
    attr_reader :shop_id, :secret_key, :gateway_url, :opts, :logger
    cattr_accessor :proxy

    TRANSACTION_OPERATIONS = %w(renotify recover confirm proof).freeze

    def initialize(params)
      @shop_id = params.fetch(:shop_id)
      @secret_key = params.fetch(:secret_key)
      @gateway_url = params.fetch(:gateway_url)
      @opts = params[:options] || {}
      @logger = params[:logger] || Logger.new(STDOUT)
    end

    def query(order_id)
      get("/payments/#{order_id}")
    end

    def query_transaction(uid)
      get("/transactions/#{uid}")
    end

    def query_refund(uid)
      get("/refunds/#{uid}")
    end

    TRANSACTION_OPERATIONS.each do |op_type|
      define_method op_type.to_sym do |params|
        path = "/transactions/#{params[:uid]}/#{op_type}"
        post(path, request: params)
      end
    end

    def erip_payment(params)
      post('/payments', request: params)
    end

    def erip_refund(params)
      post('/refunds', request: params)
    end

    def bank_list(gateway_id)
      get("/gateways/#{gateway_id}/bank_list")
    end

    %i[payment refund payout credit].each do |method|
      define_method(method) do |params|
        post("/transactions/#{method}", request: params)
      end
    end

    private

    attr_reader :response

    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_TIMEOUT = 25

    def request
      begin
        Response.new(yield)
      rescue StandardError => e
        logger.error("Error: #{e.message}\nTrace:\n#{e.backtrace.join("\n")}")
        Response::Error.new(e)
      end
    end

    def connection
      @connection ||= Faraday::Connection.new(opts) do |c|
        c.options[:open_timeout] ||= DEFAULT_OPEN_TIMEOUT
        c.options[:timeout] ||= DEFAULT_TIMEOUT
        c.options[:proxy] = proxy if proxy
        c.request :json

        c.headers = {'Content-Type' => 'application/json'}.update(opts[:headers].to_h)

        c.basic_auth(shop_id, secret_key)
        c.adapter Faraday.default_adapter
      end
    end

    def post(path, data = {})
      request { connection.post(full_path(path), data.to_json) }
    end

    def get(path)
      request { connection.get full_path(path) }
    end

    def full_path(path)
      [gateway_url, path].join
    end
  end
end
