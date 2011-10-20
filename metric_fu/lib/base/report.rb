module MetricFu

  # MetricFu.report memoizes access to a Report object, that will be
  # used throughout the lifecycle of the MetricFu app.
  def self.report
    @report ||= Report.new
  end

  # = Report
  #
  # The Report class is responsible two things:
  #
  # It adds information to the yaml report, produced by the system
  # as a whole, for each of the generators used in this test run.
  #
  # It also handles passing the information from each generator used
  # in this test run out to the template class set in
  # MetricFu::Configuration.
  class Report

    # Renders the result of the report_hash into a yaml serialization
    # ready for writing out to a file.
    #
    # @return YAML
    #   A YAML object containing the results of the report generation
    #   process
    def to_yaml
      report_hash.to_yaml
    end

    def per_file_data
      @per_file_data ||= {}
    end

    def report_hash #:nodoc:
      @report_hash ||= {}
    end

    # Instantiates a new template class based on the configuration set
    # in MetricFu::Configuration, or through the MetricFu.config block
    # in your rake file (defaults to the included AwesomeTemplate),
    # assigns the report_hash to the report_hash in the template, and
    # tells the template to to write itself out.
    def save_templatized_report
      @template = MetricFu.template_class.new
      @template.report = report_hash
      @template.per_file_data = per_file_data
      @template.write
    end

    # Adds a hash from a passed report, produced by one of the Generator
    # classes to the aggregate report_hash managed by this hash.
    #
    # @param report_type Hash
    #   The hash to add to the aggregate report_hash
    def add(report_type)
      clazz = MetricFu.const_get(report_type.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase })
      inst = clazz.new

      report_hash.merge!(inst.generate_report)

      inst.per_file_info(per_file_data) if inst.respond_to?(:per_file_info)
    end

    # Saves the passed in content to the passed in directory.  If
    # a filename is passed in it will be used as the name of the
    # file, otherwise it will default to 'index.html'
    #
    # @param content String
    #   A string containing the content (usually html) to be written
    #   to the file.
    #
    # @param dir String
    #   A dir containing the path to the directory to write the file in.
    #
    # @param file String
    #   A filename to save the path as.  Defaults to 'index.html'.
    #
    def save_output(content, dir, file='index.html')
      open("#{dir}/#{file}", "w") do |f|
        f.puts content
      end
    end

    # Checks to discover whether we should try and open the results
    # of the report in the browser on this system.  We only try and open
    # in the browser if we're on OS X and we're not running in a
    # CruiseControl.rb environment.  See MetricFu.configuration for more
    # details about how we make those guesses.
    #
    # @return Boolean
    #   Should we open in the browser or not?
    def open_in_browser?
      MetricFu.configuration.platform.include?('darwin') &&
      ! MetricFu.configuration.is_cruise_control_rb?
    end

    # Shows 'index.html' from the passed directory in the browser
    # if we're able to open the browser on this platform.
    #
    # @param dir String
    #   The directory path where the 'index.html' we want to open is
    #   stored
    def show_in_browser(dir)
      system("open #{dir}/index.html") if open_in_browser?
    end
  end
end
