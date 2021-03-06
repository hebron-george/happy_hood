module HappyHood
  module Slack
    class Client
      DefaultSlackChannel = "#happy-hood".freeze
      DefaultIconEmoji = ":house_buidings:".freeze

      def self.send_daily_price_summary
        message = daily_message

        slack.chat_postMessage({
          text: message,
          icon_emoji: DefaultIconEmoji,
          channel: DefaultSlackChannel,
        })
      end

      def self.send_monthly_price_summary
        message = monthly_message

        slack.chat_postMessage({
          text: message,
          icon_emoji: DefaultIconEmoji,
          channel: DefaultSlackChannel,
        })
      end

      private

      def self.slack
        ::Slack::Web::Client.new
      end

      def self.daily_message
        neighborhood_differences = DifferenceCalculator.new(Hood.all, start_date: 1.day.ago, end_date: Date.today).differences
        messages  = DifferenceRenderer.summarize_differences(neighborhood_differences)

        messages.empty? ? 'No changes for any HappyHood' : messages
      end

      def self.monthly_message
        neighborhood_differences = DifferenceCalculator.new(Hood.all, start_date: 1.month.ago, end_date: Date.today).differences
        messages  = DifferenceRenderer.summarize_differences(neighborhood_differences)

        messages.empty? ? "Could not calculate monthly difference" : messages
      end
    end
  end
end
