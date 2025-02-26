# notable curl options
#  -f : fail on HTTP error message > 400
#  -L : follow server URL if it provides a moved location
#  -O : output to a file, using the name from the URL
#  -s : silent (no progress or errors)
#  -S : print errors in silent mode
alias curl-dl='curl -fLO'

# an alternative which has more features and is distributed with curl is wcurl
alias curlw='wcurl'
