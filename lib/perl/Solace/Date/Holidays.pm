package Solace::Date::Holidays;

# See documentation in POD format below

use strict;
use warnings;
use Data::Dumper;
use Carp;
use HTML::TableExtract;
use LWP::Simple;
use Date::Parse;

sub new {
    my $class = shift;
    my %args  = @_;

    $args{countrycode} = 'CA' if !defined $args{countrycode};
    if (!defined $args{province}) {
        if(defined $args{state}) {
            $args{province} = $args{state};
        } else {
            $args{province} = 'ON';
        }
    }

    my %self = (
        countrycode => $args{countrycode},
        province => $args{province}
        );

    bless(\%self, $class);

    return \%self;
}

sub DESTROY {
    my ($self) = @_;
}

my %holidays = 
    ( 'CA' => 
      {
          'NT' => {},
          'BC' => {
                    '2011' => {
                                '0101' => 'New Years Day',
                                '0905' => 'Labour Day',
                                '0422' => 'Good Friday',
                                '1111' => 'Remembrance Day',
                                '1010' => 'Thanksgiving Day',
                                '0523' => 'Victoria Day',
                                '0801' => 'British Columbia Day ',
                                '1225' => 'Christmas Day',
                                '0701' => 'Canada Day'
                              },
                    '2012' => {
                                '0101' => 'New Years Day',
                                '0406' => 'Good Friday',
                                '1008' => 'Thanksgiving Day',
                                '0521' => 'Victoria Day',
                                '1111' => 'Remembrance Day',
                                '0903' => 'Labour Day',
                                '1225' => 'Christmas Day',
                                '0806' => 'British Columbia Day ',
                                '0701' => 'Canada Day'
                              }
                  },
          'NS' => {},
          'MB' => {},
          'ON' => {
                    '2011' => {
                                '0101' => 'New Years Day',
                                '0221' => 'Family Day',
                                '0422' => 'Good Friday',
                                '0523' => 'Victoria Day',
                                '0701' => 'Canada Day',
                                '0801' => 'Civic Holiday',
                                '0905' => 'Labour Day',
                                '1010' => 'Thanksgiving Day',
                                '1225' => 'Christmas Day',
                                '1226' => 'Boxing Day',
                                '1227' => 'Christmas (in lieu)',
                                '1228' => 'Christmas Shutdown',
                                '1229' => 'Christmas Shutdown',
                                '1230' => 'Christmas Shutdown',
                              },
                    '2012' => {
                                '0101' => 'New Years Day',
                                '0102' => 'New Years Day (in lieu)',
                                '0220' => 'Family Day',
                                '0406' => 'Good Friday',
                                '0521' => 'Victoria Day',
                                '0701' => 'Canada Day',
                                '0702' => 'Canada Day (in lieu)',
                                '0806' => 'Civic Holiday',
                                '0903' => 'Labour Day',
                                '1008' => 'Thanksgiving Day',
                                '1225' => 'Christmas Day',
                                '1226' => 'Boxing Day',
                                '1227' => 'Christmas Shutdown',
                                '1228' => 'Christmas Shutdown',
                                '1231' => 'Christmas Shutdown',
                              },
                     '2013' => { '0101' => 'New Years Day',
                                 '0218' => 'Family Day',
                                 '0329' => 'Good Friday',
                                 '0520' => 'Victoria Day',
                                 '0701' => 'Canada Day',
                                 '0805' => 'Civic Holiday',
                                 '0902' => 'Labour Day',
                                 '1014' => 'Thanksgiving Day',
                                 '1225' => 'Christmas Day',
                                 '1226' => 'Boxing Day',
                                 '1227' => 'Christmas Shutdown',
                                 '1230' => 'Christmas Shutdown',
                                 '1231' => 'Christmas Shutdown',
                               },
                     '2014' => { '0101' => 'New Years Day',
                                 '0217' => 'Family Day',
                                 '0418' => 'Good Friday',
                                 '0519' => 'Victoria Day',
                                 '0701' => 'Canada Day',
                                 '0804' => 'Civic Holiday',
                                 '0901' => 'Labour Day',
                                 '1013' => 'Thanksgiving Day',
                                 '1225' => 'Christmas Day',
                                 '1226' => 'Boxing Day',
                                 '1229' => 'Christmas Shutdown',
                                 '1230' => 'Christmas Shutdown',
                                 '1231' => 'Christmas Shutdown',
                               },
                     '2015' => { '0101' => 'New Years Day',
                                 '0216' => 'Family Day',
                                 '0403' => 'Good Friday',
                                 '0518' => 'Victoria Day',
                                 '0701' => 'Canada Day',
                                 '0803' => 'Civic Holiday',
                                 '0907' => 'Labour Day',
                                 '1012' => 'Thanksgiving Day',
                                 '1225' => 'Christmas Day',
                                 '1228' => 'Boxing Day',
                                 '1229' => 'Christmas Shutdown',
                                 '1230' => 'Christmas Shutdown',
                                 '1231' => 'Christmas Shutdown',
                               },
                     '2016' => { '0101' => 'New Years Day',
                                 '0215' => 'Family Day',
                                 '0325' => 'Good Friday',
                                 '0523' => 'Victoria Day',
                                 '0701' => 'Canada Day',
                                 '0801' => 'Civic Holiday',
                                 '0905' => 'Labour Day',
                                 '1010' => 'Thanksgiving Day',
                                 '1226' => 'Christmas Day',
                                 '1227' => 'Boxing Day',
                                 '1228' => 'Christmas Shutdown',
                                 '1229' => 'Christmas Shutdown',
                                 '1230' => 'Christmas Shutdown',
                               },
                     '2017' => { '0102' => 'New Years Day',
                                 '0220' => 'Family Day',
                                 '0414' => 'Good Friday',
                                 '0522' => 'Victoria Day',
                                 '0703' => 'Canada Day',
                                 '0807' => 'Civic Holiday',
                                 '0904' => 'Labour Day',
                                 '1009' => 'Thanksgiving Day',
                                 '1225' => 'Christmas Day',
                                 '1226' => 'Boxing Day',
                                 '1227' => 'Christmas Shutdown',
                                 '1228' => 'Christmas Shutdown',
                                 '1229' => 'Christmas Shutdown',
                               },
                     '2018' => { '0102' => 'New Years Day',
                                 '0219' => 'Family Day',
                                 '0330' => 'Good Friday',
                                 '0521' => 'Victoria Day',
                                 '0702' => 'Canada Day',
                                 '0806' => 'Civic Holiday',
                                 '0903' => 'Labour Day',
                                 '1008' => 'Thanksgiving Day',
                                 '1225' => 'Christmas Day',
                                 '1226' => 'Boxing Day',
                                 '1227' => 'Christmas Shutdown',
                                 '1228' => 'Christmas Shutdown',
                                 '1231' => 'Christmas Shutdown',
                               },
                     '2019' => { '0101' => 'New Years Day',
                                 '0218' => 'Family Day',
                                 '0419' => 'Good Friday',
                                 '0520' => 'Victoria Day',
                                 '0701' => 'Canada Day',
                                 '0805' => 'Civic Holiday',
                                 '0902' => 'Labour Day',
                                 '1014' => 'Thanksgiving Day',
                                 '1225' => 'Christmas Day',
                                 '1226' => 'Boxing Day',
                                 '1227' => 'Christmas Shutdown',
                                 '1230' => 'Christmas Shutdown',
                                 '1231' => 'Christmas Shutdown',
                               },
                     '2020' => { '0101' => 'New Years Day',
                                 '0217' => 'Family Day',
                                 '0410' => 'Good Friday',
                                 '0518' => 'Victoria Day',
                                 '0701' => 'Canada Day',
                                 '0803' => 'Civic Holiday',
                                 '0907' => 'Labour Day',
                                 '1012' => 'Thanksgiving Day',
                                 '1225' => 'Christmas Day',
                                 '1228' => 'Boxing Day',
                                 '1229' => 'Christmas Shutdown',
                                 '1230' => 'Christmas Shutdown',
                                 '1231' => 'Christmas Shutdown',
                               },
                     '2021' => { '0101' => 'New Years Day',
                                 '0215' => 'Family Day',
                                 '0402' => 'Good Friday',
                                 '0524' => 'Victoria Day',
                                 '0701' => 'Canada Day',
                                 '0802' => 'Civic Holiday',
                                 '0906' => 'Labour Day',
                                 '1011' => 'Thanksgiving Day',
                                 '1227' => 'Christmas Day',
                                 '1228' => 'Boxing Day',
                                 '1229' => 'Christmas Shutdown',
                                 '1230' => 'Christmas Shutdown',
                                 '1231' => 'Christmas Shutdown',
                               },
                  },
          'YT' => {},
          'QC' => {
                    '2011' => {
                                '0101' => 'New Years Day ',
                                '0905' => 'Labour Day ',
                                '1019' => 'Thanksgiving Day ',
                                '0624' => 'Fete Nationale / ',
                                '0422' => 'Good Friday * ',
                                '0523' => 'Victoria Day ',
                                '1225' => 'Christmas Day ',
                                '0701' => 'Canada Day '
                              },
                    '2012' => {
                                '0101' => 'New Years Day ',
                                '0406' => 'Good Friday * ',
                                '0624' => 'Fete Nationale / ',
                                '1008' => 'Thanksgiving Day ',
                                '0521' => 'Victoria Day ',
                                '0903' => 'Labour Day ',
                                '1225' => 'Christmas Day ',
                                '0701' => 'Canada Day '
                              }
                  },
          'NF' => {},
          'NU' => {},
          'PE' => {},
          'SK' => {},
          'NB' => {},
          'AB' => {
                    '2011' => {
                                '0221' => 'Alberta Family Day',
                                '0101' => 'New Years Day',
                                '1226' => 'Boxing Day **',
                                '0905' => 'Labour Day',
                                '0422' => 'Good Friday',
                                '1111' => 'Remembrance Day',
                                '1010' => 'Thanksgiving',
                                '0523' => 'Victoria Day',
                                '1225' => 'Christmas Day',
                                '0801' => 'Heritage Day **',
                                '0701' => 'Canada Day'
                              },
                    '2012' => {
                                '0101' => 'New Years Day',
                                '0406' => 'Good Friday',
                                '1226' => 'Boxing Day **',
                                '1008' => 'Thanksgiving',
                                '0521' => 'Victoria Day',
                                '1111' => 'Remembrance Day',
                                '0220' => 'Alberta Family Day',
                                '0903' => 'Labour Day',
                                '1225' => 'Christmas Day',
                                '0806' => 'Heritage Day **',
                                '0701' => 'Canada Day'
                              }
                  }
      },
      'US' => 
      {
          'NY' => {
                    '2012' => {
                                '0101' => 'New Years Day',
                                '0102' => 'New Years Day (in lieu)',
                                '0220' => "President's Day",
                                '0528' => 'Memorial Day',
                                '0704' => 'Independence Day',
                                '0903' => 'Labour Day',
                                '1122' => 'Thanksgiving Day',
                                '1123' => 'Friday after Thanksgiving',
                                '1225' => 'Christmas Day',
                                '1226' => 'Day after Christmas',
                                '1227' => 'Christmas Shutdown',
                                '1228' => 'Christmas Shutdown',
                                '1231' => 'Christmas Shutdown',
                              },
                    '2013' => { '0101' => 'New Years Day',
                                '0218' => "President's Day",
                                '0527' => 'Memorial Day',
                                '0704' => 'Independence Day',
                                '0902' => 'Labour Day',
                                '1128' => 'Thanksgiving Day',
                                '1225' => 'Christmas Day',
                                '1226' => 'Day after Christmas',
                                '1227' => 'Christmas Shutdown',
                                '1230' => 'Christmas Shutdown',
                                '1231' => 'Christmas Shutdown',
                               },
                    '2014' => { '0101' => 'New Years Day',
                                '0217' => "President's Day",
                                '0526' => 'Memorial Day',
                                '0704' => 'Independence Day',
                                '0901' => 'Labour Day',
                                '1127' => 'Thanksgiving Day',
                                '1225' => 'Christmas Day',
                                '1226' => 'Day after Christmas',
                                '1229' => 'Christmas Shutdown',
                                '1230' => 'Christmas Shutdown',
                                '1231' => 'Christmas Shutdown',
                              }
          }
      }
    );

my %urls = (
    ON => 'http://www.statutoryholidays.com/ontario.php',
    AB => 'http://www.statutoryholidays.com/alberta.php',
    BC => 'http://www.statutoryholidays.com/bc.php',
    MB => 'http://www.statutoryholidays.com/manitoba.php',
    NF => 'http://www.statutoryholidays.com/newfoundland.php',
    NB => 'http://www.statutoryholidays.com/newbrunswick.php',
    NS => 'http://www.statutoryholidays.com/novascotia.php',
    NT => 'http://www.statutoryholidays.com/nwt.php',
    NU => 'http://www.statutoryholidays.com/nunavut.php',
    PE => 'http://www.statutoryholidays.com/pei.php',
    QC => 'http://www.statutoryholidays.com/quebec.php',
    SK => 'http://www.statutoryholidays.com/saskatchewan.php',
    YT => 'http://www.statutoryholidays.com/yukon.php',
    );

#FIXME: above URLS don't list the days the holidays are moved to when
# they fall on the weekend - a better source is needed.
# US => 'http://www.opm.gov/operating_status_schedules/fedhol/2012.asp';
# NY => 'http://en.wikipedia.org/wiki/New_York_State_government_holidays',
# NY => 'http://corporate.nyx.com/holidays-and-hours/nyse',

sub is_holiday($$$$) {
    my ($self, $year, $month, $day) = @_;

    if (!defined $month) {
        if (!defined $year) {
            # no date given, use today
            ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
            $year  += 1900;
            $month += 1;
        } else {
            # $year is a time_t?
            ($year, $month, $day) = (localtime($year))[ 5, 4, 3 ];
            $year  += 1900;
            $month += 1;
        }
    }

    croak "need year, month (1-12), day(1-31) arguments, or a time_t"
        unless defined($day);

    my $mmdd = sprintf("%02d%02d", $month, $day);

    return defined(
        $holidays{$self->{countrycode}}{$self->{province}}{$year}{$mmdd} ) ?
        1 : 0;
}

sub holidays($$) {
    my ($self, $year) = @_;

    if (!defined($year)) {
        ($year) = (localtime)[5];
        $year  += 1900;
    }

    print "     $holidays{$self->{countrycode}}{$self->{province}}{$year}\n";
    print Dumper($holidays{$self->{countrycode}}{$self->{province}}{$year});

    return
        $holidays{$self->{countrycode}}{$self->{province}}{$year}
}

# private: used to manually populate %holidays annually
sub updateDataFromWeb {
    my ($self, $year) = @_;

    if (!defined($year)) {
        ($year) = (localtime)[5];
        $year  += 1900;
    }

    foreach my $prov (keys %urls) {
        if (!defined($holidays{CA}{$prov}{$year})) {
            $self->getProvDataFromWeb($year, $prov);
        }
    }

    print Dumper(%holidays);
}

# private: use to populate %holidays
sub getProvDataFromWeb {
    my ($self, $year, $prov) = @_;

    if (!defined($year)) {
        ($year) = (localtime)[5];
        $year  += 1900;
    }

    $prov = 'ON' if !defined($prov);
    my $url = $urls{$prov};
    if (!defined($url)) {
        my @provs = sort keys %urls;
        croak "No url found, invalid province $prov. Valid codes are: @provs"
    }

    my @headings = ("Holiday", $year);

    my $page = get($url);
    croak("Failed to get stat holidays page at URL $url") if !defined($page);

#    print "URL:$url\nPAGE:\n$page\n\n";
    my $te  = new HTML::TableExtract(headers => \@headings);
    $te->parse($page);

    foreach my $row ($te->rows) {
        foreach my $col (1) {
            my $time = str2time($row->[$col]);
            if (defined $time) {
#               $row->[$col] = $time;
                my $name = $row->[0];
                $name =~ s/\n.*//mg;
                $name =~ s/\s*\*q//g;
                my ($month, $day) = (localtime($time))[ 4, 3 ];
                $month += 1;
print STDERR "FOUND $prov ", $year - $col + 1," $month $day    ", $name, " $row->[$col] $time\n";
                my $mmdd = sprintf("%02d%02d", $month, $day);
                $holidays{CA}{$prov}{$year}{$mmdd} = $name;
            }
        }
    }

#    print Dumper($te);
}

1;

__END__
=pod

=head1 NAME

Solace::Date::Holidays - A list of statutory holidays affecting Solace Systems

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Solace::Date::Holidays qw( is_holiday );

    my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
    $year  += 1900;
    $month += 1;

    my $dh = Solace::Date::Holidays->new();
    print "Excellent\n" if $dh->is_holiday( $year, $month, $day );   


    use Solace::Date::Holidays;
    
    my $dh = Solace::Date::Holidays->( countrycode => 'CA', province => 'ON' );
    my $hashref = $dh->holidays(year => 2012);

=head1 DESCRIPTION

Can extend Date::Holidays, but is written as stand-alone. Is
trustworthy for Ontario.

=head1 METHODS

=head2 new

    $dh = Solace::Date::Holidays->new( %attributes );

This constructor returns a new Solace::Date:Holidays object.  Valid
attributes include:

=over 4

=item *

countrycode

A two letter country code based on ISO3166 (or
L<Locale::Country>).  Currently, data is only available for Canada ('CA').

=item *

province

A two letter province/state code based on postal abbreviations.
Currently, data is only available for Canada ('CA').

=head2 is_holiday

Takes 3 arguments:

year, four digits

month, between 1-12

day, between 1-31

The return value from is_holiday is either a 1 or 0 indicating true or
false, indicating whether the specified date is a holiday in the given
country/province's calendar.

=head2 holidays

Takes one argument:

year, four digits

Returns a reference to a hash, where the keys are date represented as
four digits. The two first representing month (01-12) and the last two
representing day (01-31).

The value for the key in question is the local name for the holiday
indicated by the day.

=head1 LIMITATIONS

Incomplete data. Complete only for 2011, 2012 in BC, ON, QC, AB.

=head1 SEE ALSO

=over 4

=item *

L<Date::Holidays>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<richard.perrin at solacesystems.com>.

=head1 AUTHORS

=over 4

=item *

Richard Perrin <richard.perrin@solacesystems.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Solace Systems.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
