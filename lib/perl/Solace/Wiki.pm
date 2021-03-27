#############################################################################
##
## Solace::Wiki
##
## This module fetch and scrape data from the Solace Wiki.  
##
#############################################################################

package Solace::Wiki;

use strict;
use warnings;
use Data::Dumper;
use Carp;
use HTML::TableExtract;
use LWP::Simple;
use LWP::UserAgent;
use DateTime;
use Date::Parse;
use File::Temp qw/ tempfile /;



# new - create a new object to interact with the wiki
#
# Parameters:
#   o url             - base URL of the wiki
sub new {
  my $class = shift;
  my %args  = @_;

  # map {croak "Missing required argument: $_" if (!exists($args{$_}))} qw{url};

  # Ugly in a module to default to such a specific string, but it will be very
  # handy if the URL changes and we don't have to update a large number of scripts
  $args{url} = 'http://192.168.1.202:8080/solportal' if !defined $args{url};
  
  if ($args{url} !~ /Wiki.jsp/) {
    if ($args{url} !~ /\/\s*$/) {
      $args{url} .= "/Wiki.jsp";
    }
    else {
      $args{url} .= "Wiki.jsp";
    }
  }
  
  $args{url} =~ s/\?.*//;

  my %self = (url => $args{url}
      );

  bless(\%self, $class);

  return \%self;

}

sub DESTROY {
    my ($self) = @_;
}

# Catch all getter/setter
sub AUTOLOAD {
  my ($self, $value) = @_;
  our $AUTOLOAD;

  if (grep {"Solace::Wiki::$_" eq $AUTOLOAD}  qw{url}) {
    my ($attr) = ($AUTOLOAD =~ /(\w*)$/);
    $self->{$attr} = $value if defined $value;
    return $self->{$attr};
  }
  else {
    croak("Undefined method called: $AUTOLOAD");
  }

}


# Return the requested page
sub getPage {
  my ($self, $page) = @_;

  my $url = $self->{url} . "?page=$page";
  my $html = get($url);

  if (!defined($html)) {
    carp("Failed to load wiki page $page at URL $url");
  }

  return $html;

}

# Create a new page on the wiki
#
sub createPage {
  my ($self, $name, $content) = @_;

  my (undef, $filename) = tempfile("cookies_XXXXX", OPEN => 0);
  
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);
  $ua->cookie_jar({ file => $filename, autosave => 1 });
  
  my $url = $self->{url};
  $url =~ s/Wiki/Edit/;
  $url .= "?page=$name";

  my $page = $ua->get($url);

  if ($page->is_success) {
    my $html = $page->decoded_content();
    my ($ygendc) = ($html =~ /ygendc.*?value="([\-\d]+)"/);

    push @{ $ua->requests_redirectable }, 'POST';
    # $url =~ s/Edit/PageModified/;
    my $response = $ua->post($url,
                             Content => [
                               page => $name,
                               action => 'save',
                               encodingcheck => 'ぁ',
                               ygendc => $ygendc,
                               ok => 'Save',
                               submit_auth => '',
                               changenote => '',
                               tbFIND => '',
                               tbREPLACE => '',
                               tbGLOBAL => 'on',
                               _editedtext => $content
                             ]
                             
        );
    
    if ($response->is_success) {
      return 1;
    }

    # The UA appears to be returning a failure even when it works
    # Just always return a 1
    #return 1;
  }

  return undef;
  
}


# Send a CLI command
#
# Parameters:
#   o page          - Wiki page name
#   o table         - Table description as required by HTML::TableExtract
#   o timeColumns   - Array of column numbers that have time values that
#                     should be converted to DataTime objects
sub getTableOnPage {
  my ($self, %args) = @_;

  map {croak "Missing required argument to getTableOnPage: $_" if (!exists($args{$_}))} qw{page table};

  my $url = $self->{url} . "?page=$args{page}";
  my $page = get($url);

  if (!defined($page)) {
    croak("Failed to load wiki page $page at URL $url");
  }
  my $te  = new HTML::TableExtract(%{$args{table}});
  $te->parse($page);
  
  if ($args{timeColumns}) {
    foreach my $table ($te->tables) {
      # Go through the specified columns and try to convert the cells to times
      foreach my $row ($table->rows) {
        foreach my $col (@{$args{timeColumns}}) {
          my $time = str2time($row->[$col]);
          if (defined $time) {
            $row->[$col] = $time;
          }
        }
      }
    }
  }
    
  return $te;
}

1;
