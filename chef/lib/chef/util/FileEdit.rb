class FileEdit

  require 'ftools'

  private
  attr_accessor :filename, :contents, :match

  public
  
  def initialize(filepath)
    @filename = filepath
    @match = false
    
    raise ArgumentError, "File doesn't exist" unless File.exist? @filename
    raise ArgumentError, "File is blank" unless (@contents = File.new(@filename).readlines).length > 0
    
  end
  
  #search the file line by line and match each line with the given regex
  #if matched, replace the whole line with newline.
  def search_file_replace_line(regex, newline)
    search_match(regex, newline, 'r', 1)
  end

  #search the file line by line and match each line with the given regex
  #if matched, replace the match (all occurances)  with the replace parameter
  def search_file_replace(regex, replace)
    search_match(regex, replace, 'r', 2)
  end
  
  #search the file line by line and match each line with the given regex
  #if matched, delete the line
  def search_file_delete_line(regex)
    search_match(regex, " ", 'd', 1)
  end
  
  #search the file line by line and match each line with the given regex
  #if matched, delete the match (all occurances) from the line
  def search_file_delete(regex)
    search_match(regex, " ", 'd', 2)
  end

  #search the file line by line and match each line with the given regex
  #if matched, insert newline after each matching line
  def insert_line_after_match(regex, newline)
    search_match(regex, newline, 'i', 0)
  end
   
  #Make a copy of old_file and write new file out (only if file changed)
  def write_file
    # @match is false when there is no match in the whole file. Nothing need to be done.
    if @match == true
      File.copy(@filename, @filename + ".old")
      newfile = File.new("temp", "w")
      @contents.each() do |line|
        newfile.puts(line)
      end
      newfile.close
      File.rename("temp", @filename)
    end
    @match = false
  end
  
  private
  
  #helper method to do the match, replace, delete, and insert operations
  #command is the switch of delete, replace, and insert ('d', 'r', 'i')
  #method is to control operation on whole line or only the match (1 for line, 2 for match)
  def search_match(regex, replace, command, method)
  
    #check if regex is Regexp object or simple string and store the Regexp object in exp.
    (regex.kind_of? Regexp)? exp = regex : exp = Regexp.new(regex)

    #loop through @contents and do the appropriate operation depending on 'command' and 'method'
    i = 0
    begin
      line = @contents[i]
      if line =~ exp
        @match = true
        case
        when command == 'r'
          (method == 1)? @contents[i] = replace: @contents[i].gsub!(exp, replace)
        when command == 'd'
          if method == 1
            @contents.delete_at(i)
            i = i - 1
          else
            @contents[i].gsub!(exp, "")
          end
        when command == 'i'
          @contents.insert(i+1, replace)
        end
      end
      i = i+1
    end until i == @contents.length
  end
end

#test
if __FILE__ == $0
  fedit = FileEdit.new("test")
  
  fedit.insert_line_after_match(/test/, "new Line Inserted")
  fedit.search_file_replace(/test/, "replace")
  fedit.search_file_replace_line(/replace/, "this line is replaced")
  fedit.search_file_delete(/this/)
  fedit.search_file_delete_line(/new/)
  fedit.write_file()
end
