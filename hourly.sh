#!/bin/bash

set -x
set -e

host=$(hostname -a)


crontab -u root -l | grep -v '/var/log/first-backup.log'  | crontab -u root -

touch ~/plan.json

. /root/.config/swissbackup/openrc.sh

usage () {
        echo "$0 --folders-to-backup <folder1>[,folder2,folder3,...]"
        exit 1
}
for i in $@ ; do
        case "${1}" in
        "--folders-to-backup"|"-f")
        echo $1
                if [ -z "${2}" ] ; then
                        echo "No parameter defining the --folder-to-backup parameter"
                        usage
                fi
                FOLDER_TO_BACKUP="${2}"
                shift
                shift
        ;;
        *)
        ;;
        esac
done

usage2() {  1>&2; exit 1; }

while getopts "s:h:d:w:m:y:" o; do
    case "${o}" in

        s)
            last_snapshot=${OPTARG}
            ;;


        h)
            hour=${OPTARG}
            ;;
        d)
            day=${OPTARG}
            ;;
        w)
            week=${OPTARG}
            ;;

        m)
            month=${OPTARG}
            ;;

        y)
            year=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

FOLDERS_TO_BACKUP=$(echo ${FOLDER_TO_BACKUP} | tr -d  ' ' | tr  ',' ' ' )

for i in ${FOLDERS_TO_BACKUP}"" ; do

eval "/usr/bin/restic backup --hostname $host --tag $i $i"

done

for p in ${FOLDERS_TO_BACKUP}"" ; do

sleep 15
restic unlock

eval "/usr/bin/restic forget --tag $p --keep-hourly 24 --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 3 --prune"
done

echo " last = ${last_snapshot}"
echo " year = ${year}"


> ~/plan.json

function loopOverArray(){

   restic snapshots --json | jq -r '.?' | jq -c '.[]'| while read i; do
         id=$(echo "$i" | jq -r '.| .short_id')
         ctime=$(echo "$i" | jq -r '.| .time' | cut -f1 -d".")
         hostname=$(echo "$i" | jq -r '.| .hostname')
        paths=$(echo "$i" | jq -r '. | .paths | join(",")')

        printf "id: %-25s - %-35s - %-25s paths: %-10s \n" $id $ctime $hostname $paths >> ~/plan.json
         done
  }

   loopOverArray
