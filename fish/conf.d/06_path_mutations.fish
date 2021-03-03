set -l paths_to_add \
    "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin"
# keep appending more path stings

for path_to_add in $paths_to_add
    test -d $path_to_add; and set -gx PATH $path_to_add (string match -v $path_to_add $PATH)
end
