class Chef
  module ResourceHelpers
    module Cron

      WEEKDAYS = {
        sunday: "0", monday: "1", tuesday: "2", wednesday: "3", thursday: "4", friday: "5", saturday: "6",
        sun: "0", mon: "1", tue: "2", wed: "3", thu: "4", fri: "5", sat: "6"
      }.freeze

      # Convert weekday input value into crontab format that
      # could be written in the crontab
      # @return [Integer, String] A weekday formed as per the user inputs.
      def weekday_in_crontab(wday)
        weekday = wday.to_s.downcase.to_sym
        weekday_in_crontab = WEEKDAYS[weekday] || wday
      end

      extend self
    end
  end
end
