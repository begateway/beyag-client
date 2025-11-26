require 'spec_helper'

RSpec.describe Beyag::AsyncClient do
  let(:params) do
    {
      shop_id: 1,
      secret_key: 'secret_key',
      gateway_url: 'https://api.begateway.com/beyag'
    }
  end

  describe 'async methods' do
    let(:client) { described_class.new(params) }
    let(:successful_response) { OpenStruct.new(status: 200, body: response_body) }

    context 'async transaction methods' do
      subject { client }

      it { should respond_to :payment }
      it { should respond_to :credit }
      it { should respond_to :payout }
      it { should respond_to :refund }
      it { should respond_to :bank_list }
      it { should respond_to :query }
      it { should respond_to :query_refund }
      it { should respond_to :erip_payment }
      it { should respond_to :erip_refund }
    end

    context '#payment' do
      context 'success async response' do
        let(:request_params) {
          {
            "amount" => 100,
            "currency" => "BYR",
            "description" => "Оплата заказа #3",
            "email" => "ivanpetrov@tut.by",
            "ip" => "127.0.0.8",
            "order_id" => 123456789012,
            "notification_url" =>  "http://merchant.example.com",
            "customer" => {
              "first_name" => "Иван",
              "last_name" => "Петров",
              "country" => "BY",
              "city" => "Пинск",
              "zip" => "220000",
              "address" => "ул Червякова",
              "phone" => "+375172000000"
            },
            "payment_method" => {
              "type" => "erip",
              "account_number" => "321",
              "service_no" => "99999999",
              "instruction" => ["Платежи -> Минск -> Интернет магазины -> Доставка счастья"],
              "service_info" => ["Уважаемый Клиент", "Подтвердите оплату заказа №123"],
              "receipt" =>  ["Спасибо за оплату заказа №123, наши операторы свежутся с вами"]
            }
          }
        }
        let(:request_id) { 'fa8caf55-c845-4237-9056-e6a324d5f02d' }
        let(:response_body) { {"status" => "processing",
                               "request_id" => request_id,
                               "status_url" => "https://api.begateway.com/beyag/async/status/#{request_id}",
                               "response_url" => "https://api.begateway.com/beyag/async/result/#{request_id}"} }
        let(:response_obj) { { body: response_body.to_json, status: 200 } }

        before do
          stub_request(:post, "https://api.begateway.com/beyag/async/transactions/payment").to_return(response_obj)
        end

        subject { client.payment(request_params) }

        it 'returns success response' do
          response = subject

          expect(response.request_id).to eq(request_id)
          expect(response.status_url).to eq("https://api.begateway.com/beyag/async/status/#{request_id}")
          expect(response.response_url).to eq("https://api.begateway.com/beyag/async/result/#{request_id}")
        end
      end
    end

    context '#result' do
      let(:request_id) { 'fa8caf55-c845-4237-9056-e6a324d5f02d' }
      let(:response_body) {
        {
          "transaction" => {
            "uid"=>"76505569-77ba8f7b53",
            "status"=>"successful",
            "amount"=>100,
            "currency"=>"USD",
            "description"=>"Test transaction ütf"
          }
        }
      }
      let(:request_params) { { request_id: request_id } }
      let(:response_obj) { { body: response_body.to_json, status: 200 } }

      before do
        stub_request(:get, "https://api.begateway.com/beyag/async/result/#{request_id}").to_return(response_obj)
      end

      it 'returns response' do
        res = client.result(request_params)

        expect(res.status).to eq(200)
        expect(res.transaction).to be_present
      end
    end
  end
end
