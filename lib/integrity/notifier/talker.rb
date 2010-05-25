require 'net/http'
require 'net/https'

module Integrity
  class Notifier
    class Talker < Notifier::Base
      attr_reader :account_name, :room_id, :token
      
      def self.to_haml
        <<-haml
%p.normal
  %label{ :for => "talker_notifier_account_name" } Account name
  %input.text#talker_notifier_account_name{ :name => "notifiers[Talker][account_name]", :type => "text", :value => config["account_name"] }
%p.normal
  %label{ :for => "talker_notifier_room_id" } Room id
  %input.text#talker_notifier_room_id{ :name => "notifiers[Talker][room_id]", :type => "text", :value => config["room_id"] }
%p.normal
  %label{ :for => "talker_notifier_token" } Token
  %input.text#talker_notifier_token{ :name => "notifiers[Talker][token]", :type => "text", :value => config["token"] }
        haml
      end

      def initialize(build, config={})
        log("Initializing...")
        @account_name = config.delete("account_name")
        log("\taccount name is '#{account_name}'")
        @room_id = config.delete("room_id")
        log("\trook id is '#{room_id}'")
        @token = config.delete("token")
        log("\ttoken is '#{token}'")
        super
      end

      def deliver!
        if build.successful?
          talk
        else
          talk
        end
      end

      def talk
        log('Build finished, messaging talker app.')
        msg = "#{build.project.name} - #{short_message} (#{build_url})"
        log(msg)
        post(msg)
      end

      def post(msg)
        req = Net::HTTP::Post.new("/rooms/#{room_id}/messages.json")
        req["Content-Type"] = "application/json"
        req["X-Talker-Token"] = token
        req.body = {'message' => msg}.to_json
        request(req)
      end

      def request(req)
        http = Net::HTTP.new("#{account_name}.talkerapp.com", 443)
        http.use_ssl = true
        res = http.request(req)
        unless res.kind_of?(Net::HTTPSuccess)
          log_failure(req, res)
        end
        res
      end

      def log_failure(req, res)
        log("ERROR sending message to Talker:")
        log("\trequest:")
        log("#{req.inspect}")
        log("\tresponse:")
        log("#{res.inspect}")
      end

      def log(msg)
        Integrity.log('Talker') {msg}
      end
    end

    register Talker
  end
end
