# https://github.com/vaniacer/bash_color
#----------------------------------------------------------------------+
#Color picker, usage: printf ${BLD}${CUR}${RED}${BBLU}"Some text"${DEF}|
#---------------------------+--------------------------------+---------+
#        Text color         |       Background color         |         |
#------------+--------------+--------------+-----------------+         |
#    Base    |Lighter\Darker|    Base      | Lighter\Darker  |         |
#------------+--------------+--------------+-----------------+         |
RED='\e[31m'; LRED='\e[91m'; BRED='\e[41m'; BLRED='\e[101m' #| Red     |
GRN='\e[32m'; LGRN='\e[92m'; BGRN='\e[42m'; BLGRN='\e[102m' #| Green   |
YLW='\e[33m'; LYLW='\e[93m'; BYLW='\e[43m'; BLYLW='\e[103m' #| Yellow  |
BLU='\e[34m'; LBLU='\e[94m'; BBLU='\e[44m'; BLBLU='\e[104m' #| Blue    |
MGN='\e[35m'; LMGN='\e[95m'; BMGN='\e[45m'; BLMGN='\e[105m' #| Magenta |
CYN='\e[36m'; LCYN='\e[96m'; BCYN='\e[46m'; BLCYN='\e[106m' #| Cyan    |
GRY='\e[37m'; DGRY='\e[90m'; BGRY='\e[47m'; BDGRY='\e[100m' #| Gray    |
#------------------------------------------------------------+---------+
# Effects                                                              |
#----------------------------------------------------------------------+
DEF='\e[0m'   # Default color and effects                              |
BLD='\e[1m'   # Bold\brighter                                          |
DIM='\e[2m'   # Dim\darker                                             |
CUR='\e[3m'   # Italic font                                            |
UND='\e[4m'   # Underline                                              |
INV='\e[7m'   # Inverted                                               |
COF='\e[?25l' # Cursor Off                                             |
CON='\e[?25h' # Cursor On                                              |
#----------------------------------------------------------------------+
# Text positioning, usage: XY 10 10 "Some text"                        |
XY   () { printf "\e[${2};${1}H${3}";   } #                            |
#----------------------------------------------------------------------+
# Line, usage: line - 10 | line -= 20 | line "word1 word2 " 20         |
line () { printf %.s"${1}" $(seq ${2}); } #                            |
#----------------------------------------------------------------------+
