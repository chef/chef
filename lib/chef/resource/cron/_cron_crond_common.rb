property :shell, String,
  description: "Set the `SHELL` environment variable."

property :path, String,
  description: "Set the `PATH` environment variable."

property :home, String,
  description: "Set the `HOME` environment variable."

property :command, String,
  description: "The command to be run, or the path to a file that contains the command to be run.",
  identity: true,
  required: [:create]

property :time_out, Hash,
  description: "A Hash of timeouts in the form of `({'OPTION' => 'VALUE'})`.
  Accepted valid options are:
  `preserve-status` (BOOL, default: 'false'),
  `foreground` (BOOL, default: 'false'),
  `kill-after` (in seconds),
  `signal` (a name like 'HUP' or a number)",
  default: lazy { {} },
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