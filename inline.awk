function inline(sourced_file) {
  while ((getline line < sourced_file) > 0) {
    if (line !~ /^#!/) {  # Skip shebang in sourced files
      print line
    }
  }
  close(sourced_file)
}

/^(\.|\s*source)\s+["']?([^"'\s]+)["']?/ {
  sourced_file = $2

  # Extract base directory from FILENAME
  base_dir = gensub(/\/[^\/]*$/, "", "g", FILENAME)

  # Construct full path for sourced file
  full_path = base_dir "/" sourced_file

  # Inline sourced file using constructed path
  inline(full_path)
  next 
}

{
  print
}
