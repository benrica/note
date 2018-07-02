########################SHELL共用函数###########################
##作者: damon
##日期: 20171120
##新建 add_days firstday lastday smartdt 
##版本：v1.0
################################################################

#功能：日期加减
#
#参数说明:
#	Date 日期 如 yyyy-mm-dd yyyymmdd yyyy/mm/dd
#	Num 加多少天，可以是负数
#	Type 度量类型，支持4种(y,m,d,s) 默认是 d，表示加多少天
#
#返回：yyyy-mm-dd

add_days(){
    day=`chk_dayfmt "$1"`
    num=$2
    type=$3
    type=${type:=d}
    if [[ $type == 'd' ]];then
        metric=day
    elif [[ $type == 'm' ]];then
        metric=month
    elif [[ $type == 'y' ]];then
        metric=year
    elif [[ $type == 's' ]];then
        metric=second
    else
        echo '日期度量单位只能是 y m d (年 月 日 秒),请检查..'
        exit 1
    fi
    if [[ $num =~ ^-?[0-9]+$ ]];then
        date -d "$day $num $metric" "+%F"
    else
        echo "度量值[$num]必须为整数,请检查.."
        exit 1
    fi
}

#if [[ $day =~ ^[1-9][0-9]{3}[-/]([0-1][0-9]|[1-9])[-/]([0-3][0-9]|[1-9])( [0-2][0-9]:?[0-5][0-9]:?[0-5][0-9](\.[0-9]+)?$ ]];then
chk_dayfmt(){
    day=`echo $1|awk '{print $1}'`
    if [[ $day =~ ^[1-9][0-9]{3}[-/]([0-1][0-9]|[1-9])[-/]([0-3][0-9]|[1-9])$ ]];then
        echo $day|awk -F'[-/]' '{printf("%04d-%02d-%02d",$1,$2,$3)}'
    elif [[ $day =~ ^[1-9][0-9]{3}[0-1][0-9][0-3][0-9]$ ]];then
        echo $day
    else
        echo "日期数据[$day]格式有误,请检查.."
        exit 1
    fi
}

#add_days $1 $2 $3

#功能：获取指定日期所在月分第一天的日期
#
#参数说明:
#	Date 日期 如 yyyy-mm-dd yyyymmdd yyyy/mm/dd (可选，默认当月第一天)
#
#返回：yyyy-mm-dd


#指定月份第一天,默认本月
firstday(){
    if (( $# > 0 ));then
        day=`chk_dayfmt "$1"` ;
        date -d "$day" "+%Y-%m-01"
    else
        date "+%Y-%m-01"
    fi
}

#功能：获取指定日期所在月份最后一天的日期
#
#参数说明：
#Date 日期 如 yyyy-mm-dd yyyymmdd yyyy/mm/dd (可选，默认当月最后一天)
#
#返回：yyyy-mm-dd


#指定月份最后一天,默认本月
lastday(){
    if (( $# > 0 ));then
        add_days $(firstday `add_days "$1" 1 m`) -1
    else
        add_days $(firstday `add_days $(date +%Y-%m-%d) 1 m`) -1
    fi
}

#功能：万能日期运算，精确到秒级
#
#参数说明：
#	Date 日期，支持 yyyymmdd
#yyyy-mm-dd
#yyyy/mm/dd
#yyyy-mm-dd hh24:mi:ss.0
#yyyymmddhh24miss
#yyyymmdd hh24miss
#yyyy/mm/dd hh24miss
#yyyy/mm/dd hh24:mi:ss
#	seconds 秒数，可以为负数
#
#返回：yyyy-mm-dd hh24:mi:ss[.xxx]


#万能时间转换
smartdt(){
    day="$1"
    seconds=$2
    if [[ $day =~ ^([1-9][0-9]{3})[-/]?([1-9]|[0-1][0-9])[-/]?([1-9]|[0-3][0-9])( ?([0-2][0-9]):?([0-5][0-9]):?([0-5][0-9])(\.[0-9]+)?)?$ && $seconds =~ ^-?[0-9]+$ ]];then
        if [[ $day =~ ' ' ]];then
            tim=`echo $day|awk '{print $2}'`
            day=`echo $day|awk '{print $1}'`
        else
            if [[ $day =~ [-/] ]];then
                tim=${day:10}
                day=${day:0:10}
            else
                tim=${day:8}
                day=${day:0:8}
            fi
        fi
        sec=`echo $tim|awk -F\. '{print $1}'|perl -lpe 's/^(\d{2}):?(\d{2}):?(\d{2})$/$1*3600+$2*60+$3/e'`
        mic=`echo $tim|awk -F\. '{print $2}'`
        total_addsec=$((seconds+sec))
        #echo "$day|$tim|$sec|$mic|$total_addsec"
        if [[ -z $mic ]];then
            date -d "$day $total_addsec second" "+%F %T"
        else
            date -d "$day $total_addsec second" "+%F %T.$mic"
        fi
    else
        echo "入参数据[day:$day sec:$seconds]格式有误,请检查.."
        exit 1
    fi
}
