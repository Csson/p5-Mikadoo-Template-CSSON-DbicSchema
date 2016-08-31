use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicSchema;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0006';

use MooseX::App::Command;
extends 'App::Mikadoo';
use File::ShareDir::Tarball 'dist_dir';
use Path::Tiny;
use experimental qw/postderef signatures/;

sub run($self) {
    $self->dist('Mikadoo-Template-CSSON-Dbic');

    $self->namespace_under('lib');

    $self->ask_perl_version({ from => 14 });
    $self->ask_experimentals;

    my $meta_location = path($self->location, qw<Schema Dummy.pm>);
    $self->ensure_parents_exist($meta_location);
    say $meta_location->realpath;

    for my $file (qw<Schema.pm Config.pm>) {
        $self->render(path('schema', "$file.ep") => path($self->location, $file));
    }

    for my $file (qw<Result.pm ResultSet.pm ResultBase.pm ResultSetBase.pm>) {
        $self->render(path('schema', "$file.ep") => path($self->location, 'Schema', $file));
    }

    say 'Bye.';

}

1;

__END__

=pod

=head1 SYNOPSIS

    use Mikadoo::Template::CSSON::DbicSchema::CSSON;

=head1 DESCRIPTION

Mikadoo::Template::CSSON::DbicSchema is ...

=head1 SEE ALSO

=cut
