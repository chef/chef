require 'ftools'
require 'fileutils'
require 'tempfile'

class FileEdit

  private
  
  attr_accessor :original_pathname, :contents, :file_edited

  public
  
  def initialize(filepath)
    @original_pathname = filepath
    @file_edited = false
    
    raise ArgumentError, "File doesn't exist" unless File.exist? @original_pathname
    raise ArgumentError, "File is blank" unless (@contents = File.new(@original_pathname).readlines).length > 0
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
    
    # file_edited is false when there was no match in the whole file and thus no contents have changed.
    if file_edited
      backup_pathname = original_pathname + ".old"
      File.copy(original_pathname, backup_pathname)
      Tempfile.open("w") do |newfile|
        contents.each do |line|
          newfile.puts(line)
        end
        newfile.flush
        FileUtils.mv(newfile.path, original_pathname)
      end
    end
    self.file_edited = false

  end
  
  private
  
  #helper method to do the match, replace, delete, and insert operations
  #command is the switch of delete, replace, and insert ('d', 'r', 'i')
  #method is to control operation on whole line or only the match (1 for line, 2 for match)
  def search_match(regex, replace, command, method)
    
    #check if regex is Regexp object or simple string and store the Regexp object in exp.
    exp = (regex.respond_to?(:gsub!) ? regex : Regexp.new(regex.to_s))

    #loop through contents and do the appropriate operation depending on 'command' and 'method'
    new_contents = []
    
    contents.each do |line|
      if exp.match(line) # =~ exp
        self.file_edited = true
        case
        when command == 'r'
          new_contents << ((method == 1) ? replace : line.gsub!(exp, replace))
        when command == 'd'
          if method == 2
            new_contents << line.gsub!(exp, "")
          end
        when command == 'i'
          new_contents << line
          new_contents << replace
        end
      else
        new_contents << line
      end
    end

    self.contents = new_contents
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
