# -*- coding: utf-8 -*-
require 'spec_helper'
require 'json'

RSpec.describe Beyag::Client do
  let(:client) do
    Beyag::Client.new(shop_id: '1',
                      secret_key: '123new',
                      gateway_url: 'https://api.begateway.com/beyag')
  end

  let(:success_response) do
    {
      "transaction" => {
        "type" => "payment",
        "billing_address" => {
          "first_name" => "Иван",
          "last_name" => "Петров",
          "country" => "BY",
          "city" => "Пинск",
          "address" => "ул Червякова",
          "zip" => "220000",
          "phone" => "+375172000000"
        },
        "customer" => {
          "email" => "ivanpetrov@tut.by",
          "ip" => "127.0.0.8"
        },
        "payment" => {
          "ref_id" => nil,
          "message" => "Требование на оплату счета создано.",
          "status" => "pending",
          "gateway_id" => 479
        },
        "id" => "c7775662-aed8-44d0-839c-29468e9162fb",
        "uid" => "c7775662-aed8-44d0-839c-29468e9162fb",
        "order_id" => "123456789012",
        "status" => "pending",
        "message" => "Требование на оплату счета создано.",
        "amount" => 100,
        "currency" => "BYR",
        "description" => "Оплата заказа #3",
        "tracking_id" => "123456789012",
        "created_at" => "2015-12-15T13:22:11.116Z",
        "test" => true,
        "payment_method_type" => "erip",
        "erip" => {
          "request_id" => nil,
          "service_no" => 99999999,
          "account_number" => "321",
          "transaction_id" => nil,
          "instruction" => ["Платежи -> Минск -> Интернет магазины -> Доставка счастья"],
          "service_info" => ["Уважаемый Клиент", "Подтвердите оплату заказа №123"],
          "receipt" => ["Спасибо за оплату заказа №123, наши операторы свежутся с вами"]
        }
      }
    }
  end

  let(:failed_response) do
    {
      "message" => "Invalid shop_id/secret_key.",
      "errors" => { "system" => ["System error."] }
    }
  end

  describe '#bank_list' do
    subject { client.bank_list(1) }

    before { stub_request(:get, /bank_list/).to_return(body: body.to_json) }

    context 'successful beyag response' do
      let(:body) do
        {
          "response" => {
            "data" => {
              "channel" => [
                {
                  "country" => 'United Kingdom',
                  "name" => 'Ozone (UK Open Banking Model Bank)',
                  "id" => 'bbbbbbbb-0001-bbbb-bbbb-bbbbbbbbbbbb'
                }
              ]
            }
          }
        }
      end

      it { expect(subject.data).to eq(body) }
    end

    context 'failed beyag response' do
      let(:body) do
        {
          "response" => {
            "description" => "Something went wrong with the BankList request"
          }
        }
      end

      it { expect(subject.data).to eq(body) }
    end
  end

  describe '#erip_payment' do
    let(:params) do
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
    end

    before do
      stub_request(:post, /api.begateway.com\/beyag\/payment/).to_return(response_obj)
    end

    context 'success request' do
      let(:response_obj) { { body: success_response.to_json, status: 200 } }

      it 'gets pending response from BeYag' do
        response = client.erip_payment(params)

        expect(response.successful?).to eq(true)
        expect(response.transaction["amount"]).to eq(100)
        expect(response.payment_method["service_no"]).to eq(99999999)
        expect(response.payment_method["account_number"]).to eq("321")
      end
    end

    context 'failed request' do
      let(:response_obj) { { body: failed_response.to_json, status: 401 } }

      it 'gets failed response from BeYag' do
        response = client.erip_payment(params)

        expect(response.successful?).to eq(false)
      end
    end
  end

  describe '#query' do
    let(:order_id) { "bbb07d8b-eb16-40a3-97a7-7e52ae11c0e4" }

    before do
      stub_request(:get, /api.begateway.com\/beyag\/payment/).to_return(response_obj)
    end

    context 'success request' do
      let(:response_obj) { { body: success_response.to_json, status: 200 } }

      it 'fetches order information' do
        response = client.query(order_id)

        expect(response.successful?).to eq(true)
        expect(response.transaction["amount"]).to eq(100)
      end
    end

    context 'failed request' do
      let(:response_obj) { { body: failed_response.to_json, status: 401 } }

      it 'gets failed response from BeYag' do
        response = client.query("")

        expect(response.successful?).to eq(false)
      end
    end
  end

  context 'transactions types' do
    let(:params) do
      {
        "request": {
          "amount": 1000,
          "currency": "USD",
          "description": "U pay safe test payment",
          "email": "svitas1997@gmail.com",
          "ip": "127.0.0.1",
          "order_id": 212777,
          "tracking_id": "TEST124512",
          "success_url": "https://github.com",
          "customer": {
            "first_name": "Vitali",
            "last_name": "Semenyuk",
            "country": "BY",
            "city": "Minsk",
            "zip": "212101",
            "address": "Dzerzhinskogo 95",
            "phone": "+37292230101",
            "birth_date": "16/12/1997"
          },
          "method": {
            "type": "visa"
          }
        }
      }
    end

    let(:successful_response) do
      {
        "transaction": {
            "uid": "af546e09-982e-4df9-8167-107d229aaf4b",
            "type": "payment",
            "status": "pending",
            "amount": 1000,
            "currency": "USD",
            "description": "U pay safe test payment",
            "created_at": "2017-12-01T05:55:03Z",
            "updated_at": "2017-12-01T05:55:04Z",
            "method_type": "u_pay_safe",
            "payment": {
                "status": "pending",
                "gateway_id": 47,
                "ref_id": "58797-1512107703-1085",
                "message": "Waiting"
            },
            "u_pay_safe": {
                "type": "visa"
            },
            "customer": {
                "email": "svitas1997@gmail.com",
                "ip": "127.0.0.1"
            },
            "message": "Waiting",
            "tracking_id": "TEST124512",
            "billing_address": {
                "first_name": "Vitali",
                "last_name": "Semenyuk",
                "country": "BY",
                "city": "Minsk",
                "zip": "212101",
                "address": "Dzerzhinskogo 95",
                "phone": "+37292230101",
                "birth_date": "1997-12-16"
            },
            "form": {
                "action": "https://testgateway.upaysafepayment.com/payment/initialize/58797-1512107703-1085",
                "method": "GET",
                "fields": []
            }
        }
      }
    end

    let(:failed_response) do
      {
        "message": "Unprocessable entity",
        "errors": {
            "request": {
              "amount": ["is missing"]
            }
        }
      }
    end

    shared_examples 'successful beyag response' do |method|
      it 'gets successful response from beyag' do
        response = client.public_send(method, params)

        expect(response).to be_successful
        expect(response).not_to be_error
        expect(response.status).to eq 200
        expect(response.message).to eq 'Waiting'
        expect(response.payment_method).to eq ({ 'type' => 'visa' })
        expect(response.id).to eq 'af546e09-982e-4df9-8167-107d229aaf4b'
        expect(response.transaction['amount']).to eq 1000
        expect(response.errors).to be_nil
      end
    end

    shared_examples 'failed beyag response' do |method|
      it 'gets failed response from beyag' do
        response = client.public_send(method, params)

        expect(response).not_to be_successful
        expect(response).to be_error
        expect(response.status).to eq 422
        expect(response.message).to eq 'Unprocessable entity'
        expect(response.payment_method).to be_empty
        expect(response.id).to be_nil
        expect(response.transaction).to be_nil
        expect(response.errors).to eq ({ "request" => { "amount" => ["is missing"] } })
      end
    end

    describe '#payment' do
      before do
        stub_request(:post, /api.begateway.com\/beyag\/transactions\/payment/).to_return(response_obj)
      end

      context 'success request' do
        let(:response_obj) { { body: successful_response.to_json, status: 200 } }

        it_behaves_like 'successful beyag response', :payment
      end

      context 'failed request' do
        let(:response_obj) { { body: failed_response.to_json, status: 422 } }

        it_behaves_like 'failed beyag response', :payment
      end
    end

    describe '#refund' do
      before do
        stub_request(:post, /api.begateway.com\/beyag\/transactions\/refund/).to_return(response_obj)
      end

      context 'success request' do
        let(:response_obj) { { body: successful_response.to_json, status: 200 } }

        it_behaves_like 'successful beyag response', :refund
      end

      context 'failed request' do
        let(:response_obj) { { body: failed_response.to_json, status: 422 } }

        it_behaves_like 'failed beyag response', :refund
      end
    end

    describe '#payout' do
      before do
        stub_request(:post, /api.begateway.com\/beyag\/transactions\/payout/).to_return(response_obj)
      end

      context 'success request' do
        let(:response_obj) { { body: successful_response.to_json, status: 200 } }

        it_behaves_like 'successful beyag response', :payout
      end

      context 'failed request' do
        let(:response_obj) { { body: failed_response.to_json, status: 422 } }

        it_behaves_like 'failed beyag response', :payout
      end
    end

    describe '#credit' do
      before do
        stub_request(:post, /api.begateway.com\/beyag\/transactions\/credit/).to_return(response_obj)
      end

      context 'success request' do
        let(:response_obj) { { body: successful_response.to_json, status: 200 } }

        it_behaves_like 'successful beyag response', :credit
      end

      context 'failed request' do
        let(:response_obj) { { body: failed_response.to_json, status: 422 } }

        it_behaves_like 'failed beyag response', :credit
      end
    end
  end

  describe "initialization" do
    let(:shop_id) { '1' }
    let(:secret_key) { '123new' }
    let(:gateway_url) { 'https://api.begateway.com/beyag' }
    let(:headers)     { {'X-Request-ID' => '112233'} }
    let(:client) do
      Beyag::Client.new(shop_id: shop_id,
                        secret_key: secret_key,
                        gateway_url: gateway_url,
                        options: {headers: headers})
    end

    it "sets shop_id" do
      expect(client.shop_id).to eq(shop_id)
    end

    it "sets secret_key" do
      expect(client.secret_key).to eq(secret_key)
    end

    it "sets gateway_url" do
      expect(client.gateway_url).to eq(gateway_url)
    end

    it "sets opts" do
      expect(client.opts).to eq(headers: headers)
    end
  end

  describe "connection" do
    context "when passed headers in options" do
      let(:headers) { {'X-Request-ID' => '112233'} }
      let(:client)  do
        Beyag::Client.new(shop_id: '1',
                          secret_key: '1',
                          gateway_url: 'url',
                          options: {headers: headers})
      end

      it "adds this headers to connection" do
        expect(client.send(:connection).headers).to include(headers)
      end
    end

    context 'when there are network issues' do
      let(:client) { Beyag::Client.new(shop_id: '1', secret_key: '1', gateway_url: 'http://example.com') }

      before do
        stub_request(:get, /example.com\/payment/).and_raise(Net::ReadTimeout)
      end

      it 'returns error response' do
        expect {
          expect(client.query('')).to be_kind_of(Beyag::Response::Error)
        }.not_to raise_exception
      end
    end
  end
  
  describe '#recover' do
    let(:params) do
      {
        uid: 'uid123',
        notify_merchant: false,
        transaction: {
          status: 'successful',
          message: 'Updated manually',
          paid_at: '2021-01-01T12:12:12Z'
        },
        action: { message: 'Updated manually', rrn: '444', state: 'successful' }
      }
    end

    let(:response_body) { { 'response' => { 'message' => 'Transaction uid123 was updated' } } }

    before do
      stub_request(:post, /api.begateway.com\/beyag\/transactions\/uid123\/recover/).to_return(response_obj)
    end

    context 'success request' do
      let(:response_obj) { { body: response_body.to_json, status: 200 } }

      it 'gets success response from BeYag' do
        response = client.recover(params)

        expect(response.successful?).to eq(true)
        expect(response.data.dig('response', 'message')).to eq('Transaction uid123 was updated')
      end
    end
  end

  describe '#renotify' do
    let(:params) do
      {
        uid: 'uid123',
      }
    end

    let(:response_body) { { 'response' => { 'message' => 'Notification has been sent' } } }

    before do
      stub_request(:post, /api.begateway.com\/beyag\/transactions\/uid123\/renotify/).to_return(response_obj)
    end

    context 'success request' do
      let(:response_obj) { { body: response_body.to_json, status: 200 } }

      it 'gets success response from BeYag' do
        response = client.renotify(params)

        expect(response.successful?).to eq(true)
        expect(response.data.dig('response', 'message')).to eq('Notification has been sent')
      end
    end
  end

  describe '#query_transaction' do
    let(:order_id) { 'uid123' }

    before do
      stub_request(:get, /api.begateway.com\/beyag\/transactions/).to_return(response_obj)
    end

    let(:transaction_response) do
      {
        'transaction'=>{
          'uid'=>'uid123',
          'type'=>'payment',
          'status'=>'successful',
          'amount'=>100,
          'currency'=>'USD',
          'description'=>'Test Payment',
          'created_at'=>'0000-00-00T00:00:00Z',
          'updated_at'=>'0000-00-00T00:00:00Z',
          'method_type'=>'erip',
          'receipt_url'=>'/test_url',
          'payment'=>{
            'status'=>'successful',
            'gateway_id'=>nil,
            'ref_id'=>'ref_id'
          },
          'test'=>false,
          'additional_data'=>{'payment_method'=>{'type'=>'alternative'}
          }
        }
      }
    end

    let(:error_response) do
      {
        'message'=>'Not found.'
      }
    end

    context 'success request' do
      let(:response_obj) { { body: transaction_response.to_json, status: 200 } }

      it 'get response from BeYag' do
        response = client.query_transaction(order_id)

        expect(response.successful?).to eq(true)
        expect(response.transaction['amount']).to eq(100)
      end
    end

    context 'failed request' do
      let(:response_obj) { { body: error_response.to_json, status: 404 } }

      it 'gets failed response from BeYag' do
        response = client.query_transaction('')

        expect(response.successful?).to eq(false)
      end
    end
  end
end
