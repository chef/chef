lines=<<-LINES
  Time.now.localtime.zone
  "EST"
LINES

lines.each_line.each_with_index do |line, index|
  puts "#{line.chomp} #=> \"#{eval line}\"" if index % 2 == 0
  puts "#{line.chomp}.encoding #=> #{(eval line).encoding}"
end
