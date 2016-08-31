use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0005';

use MooseX::App::Command;
extends 'App::Mikadoo';
with qw/
    Mikadoo::Template::CSSON::DbicResult::IntegerDetails
    Mikadoo::Template::CSSON::DbicResult::DecimalDetails
    Mikadoo::Template::CSSON::DbicResult::StringDetails
    Mikadoo::Template::CSSON::DbicResult::TimesDetails
/;
use MooseX::AttributeShortcuts;
use Path::Tiny;
use Try::Tiny;
use Types::Path::Tiny -types;
use Types::Standard -types;
use Dir::Self;
use Hash::Merge 'merge';
use syntax 'junction';
use Module::Load 'load';
use File::ShareDir::Tarball 'dist_dir';
use Set::Scalar;
use Mojo::Util 'dumper';
use experimental qw/signatures postderef/;


has columns => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    traits => ['Array'],
    clearer => 1,
    handles => {
        all_columns => 'elements',
        add_column => 'push',
        find_column => 'first',
        sort_columns => 'sort',
    },
);

has result_name => (
    is => 'rw',
);
has result_path => (
    is => 'rw',
    isa => Path,
);
has resultset_path => (
    is => 'rw',
    isa => Path,
);
has result_use_string => (
    is => 'rw',
    isa => Any,
);
has result_use_type => (
    is => 'rw',
    isa => Any,
    predicate => 1,
);
has resultset_use_string => (
    is => 'rw',
    isa => Any,
);
has resultset_use_type => (
    is => 'rw',
    isa => Any,
    predicate => 1,
);
has allowed_column_attributes => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    traits => ['Array'],
    default => sub { [qw/data_type is_foreign_key is_auto_increment unsigned is_nullable size default_value set_on_update set_on_create extra is_numeric/] },
    handles => {
        all_allowed_column_attributes => 'elements',
    },
);


sub run($self) {
    $self->dist('Mikadoo-Template-CSSON-Dbic');
    $self->namespace_under('lib');

    if($self->location->realpath->stringify !~ m{/Schema$}) {
        die sprintf 'Command must be run from a ::Schema directory. Current directory is <%s>', $self->location->realpath;
    }

    $self->setup_use_statements;
    $self->ask_perl_version({ from => 14 });
    $self->ask_experimentals;

    RESULT:
    while(1) {

        $self->result_name($self->term_get_text('Name of result source'));
        $self->enter_columns;

        $self->initialize_directories;

        $self->render(path(qw/result Result.pm.ep/) => $self->result_path);
        $self->render(path(qw/result ResultSet.pm.ep/) => $self->resultset_path);
        $self->clear_columns;

        my $reply = $self->term_get_one('Create more result classes?', [qw/yes no/], 'yes');
        last RESULT if $reply ne 'yes';
    }
    say 'Bye.';
}

sub enter_columns($self) {

    COLUMN:
    while(1) {
        my $column_name = $self->term_get_text('Column name', { shortcuts => [{ key => '.', text => 'No more column'}, { key => '?', text => 'Show added columns'}]});
        if($column_name eq '.') {
            last COLUMN;
        }
        if($column_name eq '?') {
            $self->print_columns_verbose;
            next COLUMN;
        }
        if($self->find_column(sub { $_ eq $column_name })) {
            say "Column $column_name already exists. Try again.";
            next COLUMN;
        }
        $self->add_column($self->column_details($column_name));
    }
}

sub initialize_directories($self) {

    my @parts = split /::/ => $self->result_name;
    my $filename = join '.' => (pop @parts, 'pm');

    $self->result_path($self->location->child('Result', @parts, $filename));
    $self->resultset_path($self->location->child('ResultSet', @parts, $filename));

    $self->ensure_parents_exist($self->result_path, $self->resultset_path);
    return $self;
}

sub column_details($self, $name) {

    my $column = { _name => $name };
    $column->{'data_type'} = $self->column_details_datatype;
    $column = merge($column, $self->column_details_index);

    if($column->{'data_type'} ne 'free text') {
        $column = merge($column, $self->column_details_for_type($column->{'data_type'}));
    }

    # Some data types has "(..)" in the data type question. Should not
    # feed that to DBIx::Class
    $column->{'data_type'} =~ s{\([^\)]*\)}{};

    return $column;

}

sub column_details_datatype($self) {
    my $data_type;
    DATA_TYPE:
    while(1) {
        $data_type = $self->term_get_one('Data type', $self->data_types_overview, 'free text');
        next DATA_TYPE if $data_type =~ m{^-*$};

        if($data_type eq 'free text') {
            FREE_TEXT_DATA_TYPE:
            while(1) {
                $data_type = $self->term_get_text(['Data type', '. : Back to data type list']);
                next FREE_TEXT_DATA_TYPE if !defined $data_type;
                next DATA_TYPE if $data_type eq '.';
                last DATA_TYPE;
            }
        }
        last DATA_TYPE;
    }
    return $data_type;
}

sub column_details_index($self) {

    my $index_settings = { };

    INDEX:
    while(1) {
        my $index_type = $self->term_get_one('Index type', ['none', 'primary key', 'foreign key', 'unique', 'simple index', 'named index'], 'none');

        $index_settings->{'_keyword'} = $index_type eq 'primary key'    ? 'primary_column'
                                      : $index_type eq 'unique'         ? 'unique_column'
                                      :                                   'column'
                                      ;

        last INDEX if $index_type eq 'none';
        $index_settings->{'index'} = 1 if $index_type eq 'simple index';
        $index_settings->{'is_foreign_key'} = 1 if $index_type eq 'foreign key';

        if($index_type eq 'named index') {
            INDEX_NAME:
            while(1) {
                my $index_name = $self->term_get_text('Index name');
                next INDEX_NAME if !defined $index_name;
                next INDEX if $index_name eq '.';
                $index_settings->{'index'} = $index_name;
            }
        }

        last INDEX;
    }

    return $index_settings;
}


sub data_types($self) {
    return [
        integers => [qw/tinyint smallint mediumint int bigint/],
        decimals => [qw/decimal/, 'float(m, d)', qw/double float(p)/],
        ood => [qw/bit bool/],
        strings => [qw/char varchar tinytext text mediumtext longtext binary varbinary tinyblob blob mediumblob longblob/],
        times => [qw/date datetime timestamp time year/],
    ];
}

# transform list of lists to a flat list, separated by an '--------' item
sub data_types_overview($self) {
    my $data_types = [map { push @$_ => '---------'; @$_ } grep { ref $_ eq 'ARRAY' } $self->data_types->@*];
    push @$data_types => 'free text';

    return $data_types;
}

sub column_details_for_type($self, $data_type) {
    my $groups = $self->data_types;

    my $group_name;

    GROUP:
    for my $i (0 .. scalar @$groups - 1) {
        next GROUP if $i % 2 == 1; # only interested in even indices
        next GROUP if none($groups->[$i + 1]->@*) eq $data_type;
        $group_name = $groups->[$i];
    }
    return {} if !defined $group_name;

    my $method = "column_details_for_$group_name";
    my $column_definition = $self->$method($data_type);

    my $not_allowed_attributes =  Set::Scalar->new(keys %$column_definition) - Set::Scalar->new($self->all_allowed_column_attributes);
    if($not_allowed_attributes) {
        say "Warning: The following attributes are not used: $not_allowed_attributes";
    }

    return $column_definition;

}

sub setup_use_statements($self) {

    RESULT_CLASS:
    for my $global_result_class_name ('Result', 'Result') {
        my $global_result_class = join '::' => $self->namespace, $global_result_class_name;

        try {
            load $global_result_class;
            if($global_result_class->isa('DBIx::Class::Candy')) {
                $self->result_use_string("use $global_result_class");
                $self->result_use_type('Candy');
                return;
            }
            elsif($global_result_class->isa('DBIx::Class::Core')) {
                return if $self->has_result_use_type && $self->result_use_type eq 'Candy';

                $self->result_use_string("use parent '$global_result_class'");
                $self->result_use_type('Standard');
                return;
            }
            else {
                return if $self->has_result_use_type && any(qw/Candy Standard/) eq $self->result_use_type;
                $self->result_use_string("use parent 'DBIx::Class::Core'");
                $self->result_use_type('Core');
            }
        }
        catch {
            return if $self->has_result_use_type;
            $self->result_use_string("use parent 'DBIx::Class::Core'");
            $self->result_use_type('Core');
        };
    }
    say "Found global result class of type " . $self->result_use_type;

    RESULTSET_CLASS:
    for my $global_resultset_class_name ('ResultSet', 'ResultSet') {
        my $global_resultset_class = join '::' => $self->namespace, $global_resultset_class_name;

        try {
            load $global_resultset_class;
            if($global_resultset_class->isa('DBIx::Class::Candy::ResultSet')) {
                $self->resultset_use_string("use $global_resultset_class");
                $self->resultset_use_type('Candy');
                return;
            }
            elsif($global_resultset_class->isa('DBIx::Class::ResultSet')) {
                return if $self->has_resultset_use_type && $self->resultset_use_type eq 'Candy';
                $self->resultset_use_string("use parent '$global_resultset_class'");
                $self->resultset_use_type('Standard');
                return;
            }
            else {
                return if $self->has_resultset_use_type && any(qw/Candy Standard/) eq $self->resultset_use_type;
                $self->resultset_use_string("use parent 'DBIx::Class::ResultSet'");
                $self->resultset_use_type('Core');
            }
        }
        catch {
            return if $self->has_resultset_use_type;
            $self->resultset_use_string("use parent 'DBIx::Class::ResultSet'");
            $self->resultset_use_type('Core');
        };
    }
    say "Found global resultset class of type " . $self->resultset_use_type;
}

sub print_columns_verbose($self) {
    say 'Columns:';

    my $longest_name = ($self->sort_columns(sub { length $_[1]->{'_name'} <=> length $_[0]->{'_name'} }))[0];
    my $name_length = length $longest_name;
    for my $column ($self->all_columns) {
        say sprintf "%2s %-${name_length}s  %s", ($column->{'_keyword'} eq 'primary_column' ? 'pk' : $column->{'_keyword'} eq 'unique_column' ? 'uq' : ''),
                                                 $column->{'_name'},
                                                 $column->{'data_type'};
    }
}

1;

__END__

=pod

=head1 SYNOPSIS

    use Mikadoo::Template::DbicResult;

=head1 DESCRIPTION

Mikadoo::Template::DbicResult is ...

=head1 SEE ALSO

=cut
