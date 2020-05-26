unified_mode true

TIMEOUT_OPTS = %w{duration preserve-status foreground kill-after signal}.freeze
TIMEOUT_REGEX = /\A\S+/.freeze
WEEKDAYS = {
  sunday: "0", monday: "1", tuesday: "2", wednesday: "3", thursday: "4", friday: "5", saturday: "6",
  sun: "0", mon: "1", tue: "2", wed: "3", thu: "4", fri: "5", sat: "6"
}.freeze

# Cron Validation Methods

# validate a provided value is between two other provided values
# we also allow * as a valid input
# @param spec the value to validate
# @param min the lowest value allowed
# @param max the highest value allowed
# @return [Boolean] valid or not?
def self.validate_numeric(spec, min, max)
  return true if spec == "*"

  if spec.respond_to? :to_int
    return spec >= min && spec <= max
  end

  # Lists of individual values, ranges, and step values all share the validity range for type
  spec.split(%r{\/|-|,}).each do |x|
    next if x == "*"
    return false unless x =~ /^\d+$/

    x = x.to_i
    return false unless x >= min && x <= max
  end
  true
end

# validate the provided month value to be jan - dec, 1 - 12, or *
# @param spec the value to validate
# @return [Boolean] valid or not?
def self.validate_month(spec)
  return true if spec == "*"

  if spec.respond_to? :to_int
    validate_numeric(spec, 1, 12)
  elsif spec.respond_to? :to_str
    # Named abbreviations are permitted but not as part of a range or with stepping
    return true if %w{jan feb mar apr may jun jul aug sep oct nov dec}.include? spec.downcase

    # 1-12 are legal for months
    validate_numeric(spec, 1, 12)
  else
    false
  end
end

# validate the provided day of the week is sun-sat, sunday-saturday, 0-7, or *
# Added crontab param to check cron resource
# @param spec the value to validate
# @return [Boolean] valid or not?
def self.validate_dow(spec)
  spec = spec.to_s
  spec == "*" ||
    validate_numeric(spec, 0, 7) ||
    %w{sun mon tue wed thu fri sat}.include?(spec.downcase) ||
    %w{sunday monday tuesday wednesday thursday friday saturday}.include?(spec.downcase)
end

property :minute, [Integer, String],
  description: "The minute at which the cron entry should run (`0 - 59`).",
  default: "*", callbacks: {
    "should be a valid minute spec" => ->(spec) { validate_numeric(spec, 0, 59) },
  }

property :hour, [Integer, String],
  description: "The hour at which the cron entry is to run (`0 - 23`).",
  default: "*", callbacks: {
    "should be a valid hour spec" => ->(spec) { validate_numeric(spec, 0, 23) },
  }

property :day, [Integer, String],
  description: "The day of month at which the cron entry should run (`1 - 31`).",
  default: "*", callbacks: {
    "should be a valid day spec" => ->(spec) { validate_numeric(spec, 1, 31) },
  }

property :month, [Integer, String],
  description: "The month in the year on which a cron entry is to run (`1 - 12`, `jan-dec`, or `*`).",
  default: "*", callbacks: {
    "should be a valid month spec" => ->(spec) { validate_month(spec) },
  }

property :weekday, [Integer, String, Symbol],
  description: "The day of the week on which this entry is to run (`0-7`, `mon-sun`, `monday-sunday`, or `*`), where Sunday is both `0` and `7`.",
  default: "*", coerce: proc { |wday| weekday_in_crontab(wday) },
  callbacks: {
    "should be a valid weekday spec" => ->(spec) { validate_dow(spec) },
  }

property :mailto, String,
  description: "Set the `MAILTO` environment variable."

property :user, String,
  description: "The name of the user that runs the command.",
  default: "root"

property :environment, Hash,
  description: "A Hash containing additional arbitrary environment variables under which the cron job will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})`.",
  default: lazy { {} }

private
# Convert weekday input value into crontab format that
# could be written in the crontab
# @return [Integer, String] A weekday formed as per the user inputs.
def weekday_in_crontab(wday)
  weekday = wday.to_s.downcase.to_sym
  WEEKDAYS[weekday] || wday
end