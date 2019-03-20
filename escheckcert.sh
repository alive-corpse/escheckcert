#!/bin/sh
#
# Simple certificates check tool by Evgeniy Shumilov <evgeniy.shumilov@gmail.com>
#

[ -z "$EXPIREDAYS" ] && EXPIREDAYS=30

# Logging variables
LOGGERPREF=`dirname $0`
if [ -f "$LOGGERPREF/../etc/logger.conf" ]; then
    . "$LOGGERPREF/../etc/logger.conf"
else
    #LOGLEVEL='info' # debug/info/warinig
    [ -z "$LOGLEVEL" ] && LOGLEVEL='info'
    LPREF='date +%Y.%m.%d-%H:%M:%S'
    DEFAULT_COLS=70 # If tput program is not exist
    LCOLOR=1 # 0/1
fi

c='[0m'
l0='[1;30;49m'
l1='[1;31;49m'
l2='[1;32;49m'
l3='[1;33;49m'
l4='[1;34;49m'
l5='[1;35;49m'
l6='[1;36;49m'
l7='[1;37;49m'
d0='[0;30;49m'
d1='[0;31;49m'
d2='[0;32;49m'
d3='[0;33;49m'
d4='[0;34;49m'
d5='[0;35;49m'
d6='[0;36;49m'
d7='[0;37;49m'

# DIV function
dv=''
d() {
    if [ -z "$dv" ]; then
        [ -n "$(which tput)" ] && COLS=`tput cols` || COLS="$DEFAULT_COLS"
        cnt=`echo "$COLS" | awk '{ print $1/2 }'`
        [ "$LCOLOR" = "1" ] && tpl="$l1""=""$l3""-" || tpl='=-'
        for i in `seq 1 "$cnt"`; do
            dv="$(echo "$dv$tpl")"
        done
        [ "$LCOLOR" = "1" ] && dv="$(echo "$dv$c")"
    fi
    echo "$dv"
}

# Logging function
l() {
    [ -z "$LPREF" ] && LPREF='date +%Y.%m.%d-%H:%M:%S'
    if [ -n "$2" ]; then
        case "$1" in
            d)
                if [ "$LOGLEVEL" = "debug" ]; then
                    b=''; e=''; [ "$LCOLOR" = "1" ] && b="$d4" && e="$c"
                    echo "$b"`$LPREF`"   DEBUG: $2$e"
                fi
            ;;
            i)
                if [ "$LOGLEVEL" = "debug" ] || [ "$LOGLEVEL" = "info" ]; then
                    b=''; e=''; [ "$LCOLOR" = "1" ] && b="$d2" && e="$c"
                    echo "$b"`$LPREF`"    INFO: $2$e"
                fi
            ;;
            n)
                if [ "$LOGLEVEL" = "debug" ] || [ "$LOGLEVEL" = "info" ] || [ "$LOGLEVEL" = "notice" ]; then
                    b=''; e=''; [ "$LCOLOR" = "1" ] && b="$l2" && e="$c"
                    echo "$b"`$LPREF`"  NOTICE: $2$e"
                fi
            ;;
            w)
                if [ "$LOGLEVEL" = "debug" ] || [ "$LOGLEVEL" = "info" ] || [ "$LOGLEVEL" = "warning" ] || [ "$LOGLEVEL" = "notice" ]; then
                    b=''; e=''; [ "$LCOLOR" = "1" ] && b="$d3" && e="$c"
                    echo "$b"`$LPREF`" WARNING: $2$e"
                fi
            ;;
            e)
                b=''; e=''; [ "$LCOLOR" = "1" ] && b="$d1" && e="$c"
                echo "$b"`$LPREF`"   ERROR: $2$e"
            ;;
            f)
                b=''; e=''; [ "$LCOLOR" = "1" ] && b="$l1" && e="$c"
                echo "$b"`$LPREF`"   FATAL: $2$e"
            ;;
            fe)
                b=''; e=''; [ "$LCOLOR" = "1" ] && b="$l1" && e="$c"
                echo "$b"`$LPREF`"   FATAL: $2$e"
                b=''; e=''; [ "$LCOLOR" = "1" ] && b="$d2" && e="$c"
                echo "$b"`$LPREF`"    INFO: All next operations will be cancelled...$e"
                [ -n "$3" ] && exit $3 || exit 1
            ;;
        esac
    else
        case "$1" in
            fe)
                b=''; e=''; [ "$LCOLOR" = "1" ] && b="$l1" && e="$c"
                echo "$b"`$LPREF`" FATAL: Not enough parameters.$e"
                b=''; e=''; [ "$LCOLOR" = "1" ] && b="$d2" && e="$c"
                echo "$b"`$LPREF`" INFO: All next operations will be cancelled...$e"
                exit 1
            ;;
            *)
                l i "$1"
            ;;
        esac
    fi
}

checkDate() {
    if [ -n "$2" ]; then
        sdate=`date -d "$1" +%s`
        edate=`date -d "$2" +%s`
        ltime=$(( ($edate - $sdate)/86400 ))
    else
        edate=`date -d "$1" +%s`
    fi
    delta=$(( $edate - $(date +%s) ))
    l d "Delta: $delta"
    l "Certificate expired in $(( $delta / 86400 )) days at $(date -d @"$edate" "+%F %T")"
    [ -n "$2" ] && l "Lifetime: $ltime"
	if [ $delta -gt 0 ]; then
	    [ $delta -lt $(( $EXPIREDAYS * 86400 )) ] && l w "This certificate should be updated" && ecode=1 
	else
	    l e "This certificate should be removed" && ecode=1 
	fi	
}

checkCertFile() {
    if [ -f "$1" ]; then
        if [ -n "$(grep -F 'localKeyID' "$1")" ]; then
            if enddate=`openssl x509 -in "$1" -noout -enddate | sed 's/notAfter=//' 2>/dev/null`; then
                startdate=`openssl x509 -in "$1" -noout -startdate | sed 's/notBefore=//' 2>/dev/null`
                if [ -n "$enddate" ]; then
                    d
                    l "Checking certificate $1"
					[ -n "$startdate" ] && l "Start date: $startdate"
                    l "End date: $enddate"
					[ -n "$startdate" ] && checkDate "$startdate" "$enddate" || checkDate "$enddate"
                fi
            else
                d
                w "Can't load date from certificate $1"
            fi
        else
            fcheck=`echo "$fcheck"; echo "$1"`
        fi
    fi
}

checkCertWeb() {
	if [ -n "$1" ]; then
		d
		l "Checking certificate for $1"
		if resp=`echo | openssl s_client -servername "$1" -connect "$1":443 2>/dev/null 2>/dev/null`; then
			if [ -n "$resp" ]; then
                l d "RESP: $resp"
				startdate=`echo "$resp" | openssl x509 -noout -startdate | sed 's/notBefore=//'`
				enddate=`echo  "$resp" | openssl x509 -noout -enddate | sed 's/notAfter=//'`
				[ -n "$startdate" ] && l "Start date: $startdate"
				[ -n "$enddate" ] && l "End date: $enddate"
				checkDate "$startdate" "$enddate"
			else
				l e "Can't get cert data from $1"
			fi
		else
			l e "Can't get cert data from $1"
		fi
	fi
}


help() {
    LPREF=''
    d
    echo "$l3""  This is script for checking expiring dates of certificates as by"
    echo "filenames so by domain names. If you pass directory as parameter, sript"
    echo "will find all the files with extensions *.pem and *.crt and will try to"
    echo "check  them.  If at least one of certificates  will be outdated or it's"
    echo "expiration  period is less than variable EXPIREDAYS value,  script will"
    echo "exit at the end of all checks with exitcode 1. By default EXPIREDAYS is"
    echo "equal 30.  If  you  want  to  change  this value, you can write down it"
    echo "inside script or pass in comand line like this:"
    echo "$l2""    EXPIREDAYS=60 $0 mydomain.com"
    echo "$l3""Also you can use it in your scripts  as checking  feature  for  sending"
    echo "some alerts. For example:"
    echo "$l2""    if ! expired=\`./escheckcert.sh domain1.com domain2.com\`; then"
    echo "        echo \"\$expired\" | mail -s \"Expired certs\" admin@domain.com"
    echo "    fi"
    echo
    echo "$l4""Parameters:"
    echo "$l2""    files, directories, domain names"
    echo 
    echo "$l4""Usage:"
    echo "$l2""    $0 <filename1|dirname1|domain1> [filename2|dirname2|dirname3] ..."
    echo
    echo "$l4""Example:"
    echo "$l2""    $0 ./mycert.pem /path/to/certs mydomain.com"
    echo 
    echo 
    d
}

ecode=0
fcheck=''

[ -z "$*" ] && help && exit 1

for p in $*; do
	if [ -f "$p" ]; then
		checkCertFile "$p"
	elif [ -d "$p" ]; then
		flist=`find "$p" -type f -iname "*.pem" -or -iname "*.crt"`
		for fname in $flist; do
			checkCertFile "$fname"
		done
    else
		checkCertWeb "$p"
	fi
done

d

exit $ecode

