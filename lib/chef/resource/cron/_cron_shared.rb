unified_mode true

TIMEOUT_OPTS = %w{duration preserve-status foreground kill-after signal}.freeze
TIMEOUT_REGEX = /\A\S+/.freeze
WEEKDAYS = {
  sunday: "0", monday: "1", tuesday: "2", wednesday: "3", thursday: "4", friday: "5", saturday: "6",
  sun: "0", mon: "1", tue: "2", wed: "3", thu: "4", fri: "5", sat: "6"
}.freeze

property :minute, [Integer, String],
  description: "The minute at which the cron entry should run (`0 - 59`).",
  default: "*", callbacks: {
    "should be a valid minute spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_numeric(spec, 0, 59) },
  }

property :hour, [Integer, String],
  description: "The hour at which the cron entry is to run (`0 - 23`).",
  default: "*", callbacks: {
    "should be a valid hour spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_numeric(spec, 0, 23) },
  }

property :day, [Integer, String],
  description: "The day of month at which the cron entry should run (`1 - 31`).",
  default: "*", callbacks: {
    "should be a valid day spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_numeric(spec, 1, 31) },
  }

property :month, [Integer, String],
  description: "The month in the year on which a cron entry is to run (`1 - 12`, `jan-dec`, or `*`).",
  default: "*", callbacks: {
    "should be a valid month spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_month(spec) },
  }

property :weekday, [Integer, String, Symbol],
  description: "The day of the week on which this entry is to run (`0-7`, `mon-sun`, `monday-sunday`, or `*`), where Sunday is both `0` and `7`.",
  default: "*", coerce: proc { |day| weekday_in_crontab(day) },
  callbacks: {
    "should be a valid weekday spec" => ->(spec) { Chef::ResourceHelpers::CronValidations.validate_dow(spec) },
  }

property :shell, String,
  description: "Set the `SHELL` environment variable."

property :path, String,
  description: "Set the `PATH` environment variable."

property :home, String,
  description: "Set the `HOME` environment variable."

property :mailto, String,
  description: "Set the `MAILTO` environment variable."

property :command, String,
  description: "The command to be run, or the path to a file that contains the command to be run.",
  identity: true,
  required: [:create]

property :user, String,
  description: "The name of the user that runs the command.",
  default: "root"

property :environment, Hash,
  description: "A Hash containing additional arbitrary environment variables under which the cron job will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})`. **Note**: These variables must exist for a command to be run successfully.",
  default: {}

property :time_out, Hash,
  description: "A Hash of timeouts in the form of `({'OPTION' => 'VALUE'})`. Accepted valid options are:
  - `preserve-status` (BOOL, default: 'false'),
  - `foreground` (BOOL, default: 'false'),
  - `kill-after` (in seconds),
  - `signal` (a name like 'HUP' or a number)",
  default: {},
  introduced: "15.7",
  coerce: proc { |h|
    if h.is_a?(Hash)
      invalid_keys = h.keys - TIMEOUT_OPTS
      unless invalid_keys.empty?
        error_msg = "Key of option time_out must be equal to one of: \"#{TIMEOUT_OPTS.join('", "')}\"!  You passed \"#{invalid_keys.join(", ")}\"."
        raise Chef::Exceptions::ValidationFailed, error_msg
      end
      unless h.values.all? { |x| x =~ TIMEOUT_REGEX }
        error_msg = "Values of option time_out should be non-empty strings without any leading whitespace."
        raise Chef::Exceptions::ValidationFailed, error_msg
      end
      h
    elsif h.is_a?(Integer) || h.is_a?(String)
      { "duration" => h }
    end
  }

private

# Convert weekday input value into crontab format that
# could be written in the crontab
# @return [Integer, String] A weekday formed as per the user inputs.
def weekday_in_crontab(day)
  weekday = day.to_s.downcase.to_sym
  WEEKDAYS[weekday] || day
end
