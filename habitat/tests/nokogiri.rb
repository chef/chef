require "nokogiri"

document = Nokogiri::XML("<a><b>hi</b></a>")
raise "Packaged Nokogiri failed to parse XML" unless document.at_xpath("//b").text == "hi"
