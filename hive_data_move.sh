#!/bin/bash

deal_file=$1

if [[ $# lt 1 ]];then
	echo "Useage: $0 <file>"
fi

hadoop_user=xxxxx #请替换
src_db=xxxxx #请替换

pid=$$
logfile=mv2bdp.$pid.log
msg(){
    if [[ -z $2 ]];then
        level='I'
    else
        level=$2
    fi
    echo "[$level][$(date '+%F %T')] $1" |tee -a $logfile
}

catch_interrput_singal(){
    msg "Catch interrupt singal..exit now.." "E"
    exit -1
}

trap catch_interrput_singal SIGHUP SIGINT SIGTERM

mvtobdp(){
    input_file=$1
    row=0
    while read line;do
        ((row++))
        [[ $line =~ ^\# || $line =~ ^$ ]] && msg "no:$row ($line) blank line or comment line ,next.." "W" && continue
        table=`echo $line|awk '{print $1}'`
        sid=`echo $line|awk '{print $2}'`
        [[ -z $table || -z $sid ]] && msg "no:$row line: [$line] table or target_sid not defined.." "E" && continue
        src_path=/user/hive/warehouse/${src_db}.db/$table
        #tar_path=/user/hive/warehouse/sx_bdp_liferpt_safe.db/agg_ty_cheat_report_month_list
        tar_path=/user/hive/warehouse/${sid}.db/${table,,}
        src_tar_size=`hadoop fs -du -s $src_path $tar_path 2>/dev/null`
        (( $? != 0 )) && msg "no:$row check the path[$src_path $tar_path] permission or whether the paths is exists.." "E" && continue
        src_size=`echo $src_tar_size|awk '{print $1}'`
        tar_size=`echo $src_tar_size|awk '{print $4}'`
		if (( $src_size == 0 ));then
			msg "no:$row src table size is zero(0),next.."
			continue
        elif (( $tar_size == 0 ));then
            #echo aaa &>/dev/null
            hadoop fs -mv $src_path/* $tar_path
            if (( $? != 0 ));then
                msg "no:$row Move table [$table] fail..CMD:[hadoop fs -mv $src_path/* $tar_path]" 'E'
                #exit -1 
            else
                move_size=`hadoop fs -du -s $tar_path 2>/dev/null|awk '{print $1}'`
                if (( $src_size == $move_size ));then
                    msg "no:$row move_size:$move_size Call_cmd: hadoop fs -mv $src_path/* $tar_path success.."
					hadoop fs -chown -R ${hadoop_user}:${hadoop_user} $tar_path
					if (( $? != 0 ));then
						msg "no $row call_cmd: hadoop fs -chown -R ${hadoop_user}:${hadoop_user} $tar_path failed.." "E"
						#exit -1
					else
						msg "no $row call_cmd: hadoop fs -chown -R ${hadoop_user}:${hadoop_user} $tar_path success.."
					fi
                else
                    msg "no:$row line: [$line] diff size[src:$src_size tar:$move_size],please check.." "E"
                    #exit -1
                fi
            fi
        else
            msg "no:$row line: [$line] src_size:$src_size tar_size: $tar_size > 0 ,please check.." 'E'
            #exit -1
        fi
    done < $input_file
    if (( $? == 0 ));then
        msg "Congratulation,all success done.. logfile:$logfile"
    else
        msg "Sorry,there are some errors happen,please check the log file:$logfile .."
    fi
}

mvtobdp $deal_file
