package Git::Hook::PostReceive;
use v5.12;
use Moose;
use methods-invoker;
use DateTime::Format::DateParse;
use Cwd;
use File::Basename;

method read_stdin ($line) {
    chomp $line;
    my @args = split /\s+/, $line;
    return $->run( @args );
}

method run ($before, $after, $ref) {
    my $is_new_head = $before =~ /^0{40}/;
    my $is_delete = $after =~ /^0{40}/;

    $before  = $before ne '0000000000000000000000000000000000000000' 
                ? qx(git rev-parse $before) 
                : undef;

    $after   = $after ne '0000000000000000000000000000000000000000' 
                ? qx(git rev-parse $after) 
                : undef;

    chomp($before) if $before;
    chomp($after) if $after;

    my ($ref_type,$ref_name) = ( $ref =~ m{refs/([^/]+)/(.*)$} );
    my $repo = getcwd;
    my @commits = $->get_commits($before,$after);

    # truncate commits if it's too large
    @commits = @commits[ 0..50 ] if scalar(@commits) > 50
    return {
        before     => $before,
        after      => $after,
        repository => $repo,
        ref        => $ref_name,
        ref_type   => $ref_type,
        ( $is_new_head 
            ? (new_head => $is_new_head)
            : () ),
        ( $is_delete 
            ? (delete => $is_delete)
            : () ),
        commits    => \@commits,
    };
}

method get_commits ($before,$after) {
    my $log_string;

    if( $before && $after ) {
        $log_string = qx(git rev-list --pretty $before...$after);
    }
    elsif( $after ) {
        $log_string = qx(git rev-list --pretty $after);
    }

    return ( ) unless $log_string;

    my @lines = split /\n/,$log_string;
    my @commits = ();
    my $buffer = '';
    for( @lines ) {
        if(/^commit\s/ && $buffer ) {
            push @commits,$buffer;
            $buffer = '';
        }
        $buffer .= $_ . "\n";
    }
    push @commits, $buffer;
    return reverse map { 
                my @lines = split /\n/,$_;
                my $info = {  };
                for my $line ( @lines ) {
                    given($line) {
                        when( m{^commit (.*)$}i ) { $info->{id} = $1; }
                        when( m{^author:\s+(.*?)\s<(.*?)>}i ) { 
                                $info->{author} = { 
                                    name => $1,
                                    email => $2
                                };
                            }
                        when( m{^date:\s+(.*)}i ) {  $info->{date} = $1; }
                        when( m{^merge: (\w+)\s+(\w+)}i ) { $info->{merge} = { parent1 => $1 , parent2 => $2 } }
                        default {
                            $info->{message} .= $line . "\n";
                        }
                    }
                }
                $info;
            } @commits;
}

1;
__END__

=head1 SYNOPSIS

    my $payload = Git::Hook::PostReceive->new->read_stdin( <STDIN> );

=cut
