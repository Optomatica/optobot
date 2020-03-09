module DslError
  def get_error_line(file_lines, line)
    lines = clean_up_lines(file_lines)
    line_number = lines.index(line)
    line_number.present? ? line_number + 1 : "line not found"
  end

  def clean_up_lines(lines)
    lines.each { |line| line.delete!("\s|\n") }
  end
end
