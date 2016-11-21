module SongsHelper
  def get_class_for_line(line)
    if line == ""
      "blank"
    elsif Parser.header? line
      "header"
    elsif Parser.chords? line
      "chord"
    else
      "lyric"
    end
  end

  def get_lines_for_columns
    lines = @song.chord_sheet.split("\n")
    # find a good place to split the two columns
    midpoint = lines.length / 2
    until ["lyric", "blank"].include? get_class_for_line(lines[midpoint]) do
      midpoint += 1
    end
    return lines[0 .. midpoint], lines[midpoint + 1 .. -1]
  end
end
