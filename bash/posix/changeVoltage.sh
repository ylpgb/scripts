#/bin/sh 

[[ $# -lt 3 ]] && { echo "Usage: $0 freqinKHz vol1inmV vol2inmV [apply]"; echo "Change the voltage for a freq in EPU table. vol1inmV is the voltage for the freq below 85 degress. vol2inmV is the voltage for the freq above 85 degree. apply is to whether automatically apply the commands (default is no. 1 is to apply)"; exit 1; } 

let freqinKHz=$1 
let vol1inmV=$2 
let vol2inmV=$3 
applyCfg=$4
let base0=0xe0100000 

echo "freq: $freqinKHz KHz" 
echo "vol1inmV: $vol1inmV mV" 
let val1="(vol1inmV-500)/5+1" 
echo "vol2inmV: $vol2inmV mV" 
let val2="(vol2inmV-500)/5+1"

# CPU0 
offset0=`cat /sys/kernel/debug/intel_epu/paseq1_cpu0_idx_tbl | sed -n 's/.*PASEQ_CPU0_INDEX_TABLE OFFSET(\(.*\)).*/\1/p'` 
index0=`cat /sys/kernel/debug/intel_epu/paseq1_cpu0_idx_tbl | sed -n '1!G;h;$p' | sed -n "/$freqinKHz/,/-----------/p" | grep "mV" | awk -F'|' '{print $2}'` 
let addr00=0xe0100000+offset0+8*index0 
reg00cmd=`printf "io -4 0x%x\n" $addr00` 
reg00Original=`eval $reg00cmd | awk '{print $2}'` 
reg00New=`echo $reg00Original | awk -v value="$val1" '{printf("%s%x%s", substr($0,1,2), value, substr($0,5,length($0)))}'` 

let addr01="0xe0100000+offset0+8*(index0+8)"
reg01cmd=`printf "io -4 0x%x\n" $addr01` 
reg01Original=`eval $reg01cmd | awk '{print $2}'` 
reg01New=`echo $reg01Original | awk -v value="$val2" '{printf("%s%x%s", substr($0,1,2), value, substr($0,5,length($0)))}'` 

# CPU1 
offset1=`cat /sys/kernel/debug/intel_epu/paseq2_cpu1_idx_tbl | sed -n 's/.*PASEQ_CPU1_INDEX_TABLE OFFSET(\(.*\)).*/\1/p'` 
index1=`cat /sys/kernel/debug/intel_epu/paseq2_cpu1_idx_tbl | sed -n '1!G;h;$p' | sed -n "/$freqinKHz/,/-----------/p" | grep "mV" | awk -F'|' '{print $2}'` 
let addr10=0xe0100000+offset1+8*index1 
reg10cmd=`printf "io -4 0x%x\n" $addr10` 
reg10Original=`eval $reg10cmd | awk '{print $2}'` 
reg10New=`echo $reg10Original | awk -v value="$val1" '{printf("%s%x%s", substr($0,1,2), value, substr($0,5,length($0)))}'` 

let addr11="0xe0100000+offset1+8*(index1+8)"
reg11cmd=`printf "io -4 0x%x\n" $addr11` 
reg11Original=`eval $reg11cmd | awk '{print $2}'` 
reg11New=`echo $reg11Original | awk -v value="$val2" '{printf("%s%x%s", substr($0,1,2), value, substr($0,5,length($0)))}'` 

printf "base:    [0x%x]\n" $base0 
printf "offset0: [0x%x]\n\n" $offset0 
printf "index00: [0x%x]\n" $index0 
printf "addr00:  [0x%x]\n" $addr00 
printf "Value:   [0x%s]->[0x%s]\n\n" $reg00Original $reg00New 
printf "index01: [0x%x]\n" $(($index0+8))
printf "addr01:  [0x%x]\n" $addr01 
printf "Value:   [0x%s]->[0x%s]\n\n" $reg01Original $reg01New 
printf "offset1: [0x%x]\n" $offset1 
printf "index1:  [0x%x]\n" $index1 
printf "addr10:  [0x%x]\n" $addr10 
printf "Value:   [0x%s]->[0x%s]\n\n" $reg10Original $reg10New 
printf "index11: [0x%x]\n" $(($index11+8))
printf "addr11:  [0x%x]\n" $addr11 
printf "Value:   [0x%s]->[0x%s]\n\n" $reg11Original $reg11New 
printf "Run following commands to change the voltage\n" 
printf "pm_util -sf1248000\n" 
echo $reg00cmd 
printf "io -4 -w 0x%x 0x%s\n" $addr00 $reg00New 
echo $reg01cmd 
printf "io -4 -w 0x%x 0x%s\n" $addr01 $reg01New 
echo $reg10cmd 
printf "io -4 -w 0x%x 0x%s\n" $addr10 $reg10New 
echo $reg11cmd 
printf "io -4 -w 0x%x 0x%s\n" $addr11 $reg11New 
printf "pm_util -sf%d000\n" $freqinKHz

## Uncomment below lines to run the command to change voltage
if [ "$applyCfg" == "1" ]; then
  echo "Applying config"
  cmd="pm_util -sf1248000" 
  eval "$cmd" 
  cmd=`printf "io -4 -w 0x%x 0x%s\n" $addr00 $reg00New` 
  eval "$cmd" 
  cmd=`printf "io -4 -w 0x%x 0x%s\n" $addr01 $reg01New` 
  eval "$cmd" 
  cmd=`printf "io -4 -w 0x%x 0x%s\n" $addr10 $reg10New` 
  eval "$cmd" 
  cmd=`printf "io -4 -w 0x%x 0x%s\n" $addr11 $reg11New` 
  eval "$cmd" 
  cmd=`printf "pm_util -sf%d000" $freqinKHz` 
  eval "$cmd"
fi
