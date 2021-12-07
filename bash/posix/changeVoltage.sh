#/bin/sh 
[[ $# -lt 2 ]] && { echo "Usage: $0 freqinKHz volinmV"; exit 1; } 

let freqinKHz=$1 
let volinmV=$2 
let applyCfg=$3

let base0=0xe0100000 

echo "freq: $freqinKHz KHz" 
echo "volinmV: $volinmV mV" 

let val="(volinmV-500)/5+1" 

# CPU0 
offset0=`cat /sys/kernel/debug/intel_epu/paseq1_cpu0_idx_tbl | sed -n 's/.*PASEQ_CPU0_INDEX_TABLE OFFSET(\(.*\)).*/\1/p'` 
index0=`cat /sys/kernel/debug/intel_epu/paseq1_cpu0_idx_tbl | sed -n '1!G;h;$p' | sed -n "/$freqinKHz/,/-----------/p" | grep "mV" | awk -F'|' '{print $2}'` 
let addr0=0xe0100000+offset0+8*index0 
reg0cmd=`printf "io -4 0x%x\n" $addr0` 
reg0Original=`eval $reg0cmd | awk '{print $2}'` 
reg0New=`echo $reg0Original | awk -v value="$val" '{printf("%s%x%s", substr($0,1,2), value, substr($0,5,length($0)))}'` 

# CPU1 
offset1=`cat /sys/kernel/debug/intel_epu/paseq2_cpu1_idx_tbl | sed -n 's/.*PASEQ_CPU1_INDEX_TABLE OFFSET(\(.*\)).*/\1/p'` 
index1=`cat /sys/kernel/debug/intel_epu/paseq2_cpu1_idx_tbl | sed -n '1!G;h;$p' | sed -n "/$freqinKHz/,/-----------/p" | grep "mV" | awk -F'|' '{print $2}'` 
let addr1=0xe0100000+offset1+8*index1 
reg1cmd=`printf "io -4 0x%x\n" $addr1` 
reg1Original=`eval $reg1cmd | awk '{print $2}'` 
reg1New=`echo $reg1Original | awk -v value="$val" '{printf("%s%x%s", substr($0,1,2), value, substr($0,5,length($0)))}'` 

printf "base:    [0x%x]\n" $base0 
printf "offset0: [0x%x]\n" $offset0 
printf "index0:  [0x%x]\n" $index0 
printf "addr0:   [0x%x]\n" $addr0 
printf "Value:   [0x%s]->[0x%s]\n\n" $reg0Original $reg0New 
printf "offset1: [0x%x]\n" $offset1 
printf "index1:  [0x%x]\n" $index1 
printf "addr1:   [0x%x]\n" $addr1 
printf "Value:   [0x%s]->[0x%s]\n\n" $reg1Original $reg1New 
printf "Run following commands to change the voltage\n" 
printf "pm_util -sf1248000\n" 
echo $reg0cmd 
printf "io -4 -w 0x%x 0x%s\n" $addr0 $reg0New 
echo $reg1cmd 
printf "io -4 -w 0x%x 0x%s\n" $addr1 $reg1New 
printf "pm_util -sf%d000\n" $freqinKHz

## Uncomment below lines to run the command to change voltage
if [ "$applyCfg" == "1" ]; then
  echo "Applying config"
  cmd="pm_util -sf1248000" 
  eval "$cmd" 
  cmd=`printf "io -4 -w 0x%x 0x%s\n" $addr0 $reg0New` 
  eval "$cmd" 
  cmd=`printf "io -4 -w 0x%x 0x%s\n" $addr1 $reg1New` 
  eval "$cmd" 
  cmd=`printf "pm_util -sf%d000" $freqinKHz` 
  eval "$cmd"
fi
