package GitHub::PostReceive;
use Moose;
use methods;
use methods-invoker;
use JSON;

=head2 GitHub

http://help.github.com/post-receive-hooks/

=cut

has repository => ( is => 'rw' );
has before => ( is => 'rw' );
has after => ( is => 'rw' );
has commits => ( is => 'rw' , isa => 'ArrayRef' );
has ref => ( is => 'rw' );

around BUILDARGS => sub {
    my $orig = shift;
	my $class = shift;

	if( ref($_[0]) ) {
		my $hashref = $_[0];
		return $class->$orig( %{ $hashref } );
	}
    elsif( ! ref($_[0]) ) {
        return $class->$orig( %{ decode_json($_[0]) } );
    }
	return $class->$orig( @_ );
};

method validate {
    return 0 unless $->repository && $->before && $->after && $->commits;
    return 1;
}

method to_json {
    return encode_json( $->to_hashref );
}

method to_hashref {
    return { 
        repository => $->repository,
        before => $->before,
        after => $->after,
        commits => $->commits,
        ref => $->ref
    };
}

1;
