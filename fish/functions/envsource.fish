# Function name: envsource
# Usage: envsource <path/to/env/file>

function envsource --description 'This function reads a configuration file where each line is an environment variable, in the format KEY=VALUE. It ignores blank lines or comment lines (those beginning with #). It splits each eligible line at the first = and exports the key-value pair as a global shell variable. It indicates successful exports by printing "Exported key <KEY>".'

  # Store the first argument into a local variable called "envfile"
  set -f envfile "$argv"

  # Check if envfile is a file and exists
  if not test -f "$envfile"

    # Print an error message and return 1, indicating an error, if the file does not exist
    echo "Unable to load $envfile"
    return 1
  end

  # Read each line from envfile
  while read line

    # Ignore lines that are comment lines (beginning with #) or empty lines
    if not string match -qr '^#|^$' "$line"

      # Split the line into key-value pair by the first = sign
      set item (string split -m 1 '=' $line)

      # Export the key-value pair as a global shell variable
      set -gx $item[1] $item[2]

      # Print successful export statement
      echo "Exported key $item[1]"

    end
  end < "$envfile"
end
