package Solace::Sm::Env;

our $cvswd = $ENV{"CVSWD"};
if (!$cvswd) {
    $cvswd = `svn info | grep 'Working Copy Root Path'`;
    $cvswd =~ s/Working Copy Root Path: //;
    chomp($cvswd);
}
$cvswd or die("CVSWD must be set");

our $baseobjdir =
    ($ENV{"BASEOBJDIR"} ? $ENV{"BASEOBJDIR"} : 'obj_Linux-i386-gcc4_debug');
our $objdir =
    ($ENV{"SCBROBJDIR"} ? $ENV{"SCBROBJDIR"} : 'obj_gcc4_sm_debug');

our $ldpath =
	"/opt/soldev/gcc-4.6.3/lib:" .
	"/opt/soldev/boost-1.54.0/lib:" .
	"$cvswd/solcbr/$objdir/lib:" . 
	"$cvswd/base/$baseobjdir:" .
	"$cvswd/solcbr/lib/third-party-libs:" .
	"$ENV{LD_LIBRARY_PATH}";

our $objdirRelative = "$cvswd/solcbr/" . $objdir;
our $objdir = $cvswd . "/solcbr/$objdir";
our $bindir = "$objdir/bin";

## Some executables from our current solcbr environment.
our $soldm = "$bindir/solacedaemon";
our $solcli = "$bindir/cli";
our $soldbg = "$bindir/soldebug";
our $soldbsp = "$bindir/soldbsysparms";

## Some aliases for executable names.
our %exeAlias = (
                 mp  => "mgmtplane",
                 cp  => "controlplane",
                 dp  => "dataplane",
                 dpl => "dataplane-linux",
                 xm  => "xmlmanager",
                );

our %numToOpMode = (1 => "tma",
                    2 => "solos",
                    3 => "soltr");



