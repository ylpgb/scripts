#!/usr/bin/perl -w
$str="MsgIdBlock[blockId=1108 bte(state=OnAdb blockId=1108 disk=0)]
 spoolerId=0 nextIndex=1109
 numOfMsgs=120 firstIndex=0 lastIndex=476
 MsgId: base=1097 first=1097 last=1216
 ReplMateMsgId: base=0 first=0 last=0 firstValid=0
 baseTS=1632720797 expiryTS=1632732797 expiryIdx=0

MsgIdBlock[blockId=1109 bte(state=OnAdb blockId=1109 disk=0)]
 spoolerId=0 nextIndex=1110
 numOfMsgs=120 firstIndex=0 lastIndex=476
 MsgId: base=1217 first=1217 last=1336
 ReplMateMsgId: base=0 first=0 last=0 firstValid=0
 baseTS=1632720797 expiryTS=1632732797 expiryIdx=0

MsgIdBlock[blockId=1110 bte(state=OnAdb blockId=1110 disk=0)]
 spoolerId=0 nextIndex=1111
 numOfMsgs=120 firstIndex=0 lastIndex=476
 MsgId: base=1337 first=1337 last=1456
 ReplMateMsgId: base=0 first=0 last=0 firstValid=0
 baseTS=1632720797 expiryTS=1632732797 expiryIdx=0

MsgIdBlock[blockId=1111 bte(state=OnAdb blockId=1111 disk=0)]
 spoolerId=0 nextIndex=1112
 numOfMsgs=120 firstIndex=0 lastIndex=476
 MsgId: base=1457 first=1457 last=1576
 ReplMateMsgId: base=0 first=0 last=0 firstValid=0
 baseTS=1632720797 expiryTS=1632732797 expiryIdx=0

MsgIdBlock[blockId=1112 bte(state=OnAdb blockId=1112 disk=0)]
 spoolerId=0 nextIndex=1113
 numOfMsgs=120 firstIndex=0 lastIndex=476
 MsgId: base=1577 first=1577 last=1696
 ReplMateMsgId: base=0 first=0 last=0 firstValid=0
 baseTS=1632720798 expiryTS=1632732798 expiryIdx=0

MsgIdBlock[blockId=1113 bte(state=OnAdb blockId=1113 disk=0)]
 spoolerId=0 nextIndex=1114
 numOfMsgs=120 firstIndex=0 lastIndex=476
 MsgId: base=1697 first=1697 last=1816
 ReplMateMsgId: base=0 first=0 last=0 firstValid=0
 baseTS=1632720798 expiryTS=1632732798 expiryIdx=0

MsgIdBlock[blockId=1114 bte(state=OnAdb blockId=1114 disk=0)]
 spoolerId=0 nextIndex=1115
 numOfMsgs=120 firstIndex=0 lastIndex=476
 MsgId: base=1817 first=1817 last=1936
 ReplMateMsgId: base=0 first=0 last=0 firstValid=0
 baseTS=1632720798 expiryTS=1632732798 expiryIdx=0

MsgIdBlock[blockId=1115 bte(state=OnAdbPinned blockId=1115 disk=0)]
 spoolerId=0 nextIndex=67108863
 numOfMsgs=80 firstIndex=0 lastIndex=316
 MsgId: base=1937 first=1937 last=2016
 ReplMateMsgId: base=0 first=0 last=0 firstValid=0
 baseTS=1632720798 expiryTS=1632732798 expiryIdx=0";

print "$str";

#%  my ($blkidlist) = ($rrsLastResult =~ /spoolerId\s*:\s+([^\s]+)/);

print "\ntest------\n";

my $id=1500;
my @blocks = $str =~ /blockId=([\d]+) disk[.\n]*/g;
my @msgIDs = $str =~ /first=([\d]+) last=([\d]+)[\n]/g;

for my $idx (0 .. $#blocks)
{
    if ($msgIDs[$idx*2] <= $id && $msgIDs[$idx*2+1] >= $id) { 
      print "block is $blocks[$idx]\n";
    }
}

