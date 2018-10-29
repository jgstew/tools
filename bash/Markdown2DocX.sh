# parameter must be a markdown file, pandoc must be installed
# reads markdown file, replaces image path so that pandoc can find the images.
cat $1 | sed 's/](\/images\//](..\/images\//g' | pandoc -f gfm -t docx -o $1.docx
