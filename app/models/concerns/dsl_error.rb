module DslError
  def get_error_line(file_lines, line)
    lines = clean_up_lines(file_lines)
    line_number = lines.index(line)
    line_number.nil? ? "line not found" : line_number + 1
  end

  def clean_up_lines(lines)
    lines.each do |line|
      line.delete!(" ")
      line.delete!("\n")
    end
  end
end
