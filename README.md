# escheckcert
Small script for checking certificates by file names, dir names, domain names

![](https://raw.githubusercontent.com/alive-corpse/escheckcert/master/screenshot.png)

  This is script for checking expiring dates of certificates as by filenames so by domain names. If you pass directory as parameter, sript will find all the files with extensions *.pem and *.crt and will try to check  them.  If at least one of certificates  will be outdated or it's expiration  period is less than variable EXPIREDAYS value,  script will exit at the end of all checks with exitcode 1. By default EXPIREDAYS is equal 30.  If  you  want  to  change  this value, you can write down it inside script or pass in comand line like this:
```bash
    EXPIREDAYS=60 ./escheckcert.sh mydomain.com
```
Also you can use it in your scripts  as checking  feature  for  sending some alerts. For example:
```bash
    if ! expired=`./escheckcert.sh domain1.com domain2.com`; then
        echo "$expired" | mail -s "Expired certs" admin@domain.com
    fi
```

### Parameters:
```
    files, directories, domain names
```
### Usage:
```bash
    ./escheckcert.sh <filename1|dirname1|domain1> [filename2|dirname2|dirname3] ...
```
### Example:
```bash
    ./escheckcert.sh ./mycert.pem /path/to/certs mydomain.com
```
