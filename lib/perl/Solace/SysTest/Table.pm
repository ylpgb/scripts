package Solace::SysTest::Table;

## Some simple Text::Table customization to make reuse easier.

use strict;
use warnings;

use Text::Table;

use Solace::SysTest::Log qw(Debug Info Warn Error DateStr);

BEGIN {
}

use constant SEP => " | ";

sub Get($) {
    my ($hdrs) = @_;

    my @newHdrs;
    foreach my $hdr (@{$hdrs}) {
	push(@newHdrs, $hdr, \SEP);
    }
    pop(@newHdrs);  ## remove trailing SEP

    return Text::Table->new(@newHdrs);
}

sub Display($$) {
    my ($title, $tbl) = @_;

    print($title . "\n" . '=' x length($title) . "\n");
    print($tbl->title());
    print($tbl->rule('-', '+'));
    print($tbl->body());
}

sub DisplayAsCsv($) {
    my ($tbl) = @_;

    my $date = DateStr();

    my $output="";
    
    my @rows = $tbl->body(0, $tbl->body_height() - 1);
    foreach my $row (@rows) { 
        #Apparently constant substitution into regexes doesn't work right.  Go figure.
        my $sep = SEP;
        $row =~ s/\s*\Q$sep\E\s*/","/g;
        $row =~ s|n/a|0|g;
	$row =~ s/\s+$//g;
	chomp $row;
        $output .= '"'.$date.'","'.$row."\"\n";
    }
    print $output
}

sub DisplayWithTotal($$) {
    my ($title, $tbl) = @_;

    ## Add a "total" row.
    my @totals;
    for (my $c = 0; $c < $tbl->n_cols(); $c++) {
	my $col = $tbl->select($c);
	my $sum = 0;
	foreach (split(/\n/, $col)) {
	    if (m/(\d+)/) {
		$sum += $1;
	    }
	}
	if (!defined($sum)) { $sum = ""; }
	push(@totals, $sum);
    }
    $totals[0] = "Total";

    $tbl->load(\@totals);

    print($title . "\n" . '=' x length($title) . "\n");
    print($tbl->title());
    print($tbl->rule('-', '+'));
    print($tbl->body(0, $tbl->body_height() - 1));
    print($tbl->rule('-', '+'));
    print($tbl->body(-1, 1));
}

END {
}

1;
 
