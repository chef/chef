class StandardTemplate < MetricFu::Template


  def write
    report.each_pair do |section, contents|
      if template_exists?(section)
        create_instance_var(section, contents)
        html = erbify(section)
        fn = output_filename(section)
        MetricFu.report.save_output(html, MetricFu.output_directory, fn)
      end
    end

    # Instance variables we need should already be created from above
    if template_exists?('index')
      html = erbify('index')
      fn = output_filename('index')
      MetricFu.report.save_output(html, MetricFu.output_directory, fn)
    end
  end

  def this_directory
    File.dirname(__FILE__)
  end
end

