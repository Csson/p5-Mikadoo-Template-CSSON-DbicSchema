use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult {

    # VERSION
    # ABSTRACT: Short intro

    use MooseX::App::Command;
    extends 'App::Mikadoo';
    use MooseX::AttributeShortcuts;
    use Path::Tiny;
    use Try::Tiny;
    use Types::Path::Tiny -types;
    use Types::Standard -types;
    use Dir::Self;
    use Hash::Merge 'merge';
    use syntax 'junction';
    use Module::Load 'load';
    use Mojo::Util 'dumper';
    use experimental qw/signatures postderef/;


    has columns => (
        is => 'ro',
        isa => ArrayRef,
        default => sub { [] },
        traits => ['Array'],
        handles => {
            all_columns => 'elements',
            add_column => 'push',
            find_column => 'first',
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
    );
    has resultset_use_string => (
        is => 'rw',
        isa => Any,
    );
    has resultset_use_type => (
        is => 'rw',
        isa => Any,
    );

    sub run($self) {
       # $self->dir(__DIR__);
        $self->dist('Mikadoo-Template-DbicResult');
        $self->namespace_under('lib');

        if($self->location->realpath->stringify !~ m{/Schema$}) {
            die sprintf 'Command must be run from a ::Schema directory. Current directory is <%s>', $self->location->realpath;
        }

        $self->setup_use_statements;

        $self->result_name($self->term_get_text('Name of result source'));
        $self->ask_perl_version({ from => 14 });
        $self->ask_experimentals;
        $self->enter_columns;

        $self->initialize_directories;

        $self->render(path(qw/result Result.pm.ep/) => $self->result_path);
        $self->render(path(qw/result ResultSet.pm.ep/) => $self->resultset_path);
    }

    sub enter_columns($self) {

        COLUMN:
        while(1) {
            my $column_name = $self->term_get_text('Column name');
            if($column_name eq '.') {
                last COLUMN;
            }
            if($column_name eq '?') {
                say 'Columns:';
                for my $column ($self->all_columns) {
                    say "  $column";
                }
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
        return $self->$method($data_type);

    }

    sub column_details_for_integers($self, $data_type) {
        my $attributes = $self->term_get_multi('Attributes', [qw/is_auto_increment unsigned is_nullable zerofill none/], ['none']);
        my $settings = {
            is_numeric => 1,
        };

        $settings->{'is_auto_increment'} = 1 if any(@$attributes) eq 'is_auto_increment';
        $settings->{'is_nullable'} = 1 if any(@$attributes) eq 'is_nullable';
        $settings->{'extra'}{'unsigned'} = 1 if any(@$attributes) eq 'unsigned';
        $settings->{'extra'}{'zerofill'} = 1 if any(@$attributes) eq 'zerofill';

        DEFAULT:
        while(1) {
            my $reply = $self->term_get_text(['Default value', ". : Don't set", '! : Set as null']);
            
            if($reply eq '.') {
                last DEFAULT if $reply eq '.';
            }
            if($reply eq '!') {
                $settings->{'default_value'} = undef;
                last DEFAULT if $reply eq '!';
            }
            if($reply =~ m{\D}) {
                say 'Only integers';
                next DEFAULT;
            }
            $settings->{'default_value'} = $reply;
            last DEFAULT;
        }

        DISPLAY_WIDTH:
        while(1) {
            my $reply = $self->term_get_text(['Max display width', '0..255', "[enter] : don't set'"]);
            last DISPLAY_WIDTH if !defined $reply;

            if($reply !~ m{\D} && $reply >= 0 && $reply <= 255) {
                $settings->{'size'} = $reply;
                last DISPLAY_WIDTH;
            }
            say 'Illegal value';
        }

        return $settings;
    }

    sub setup_use_statements($self) {

        my $global_result_class = join '::' => $self->namespace, 'Result';
        try {
            load $global_result_class;
            if($global_result_class->isa('DBIx::Class::Candy')) {
                $self->result_use_string("use $global_result_class");
                $self->result_use_type('Candy');
            }
            elsif($global_result_class->isa('DBIx::Class::Core')) {
                $self->result_use_string("use parent '$global_result_class'");
                $self->result_use_type('Standard');
            }
            else {
                say "Note: No custom $global_result_class class found. Inherits from DBIx::Class::Core."; 
                $self->result_use_string("use parent 'DBIx::Class::Core'");
                $self->result_use_type('Core');
            }
        }
        catch {
            say "Note: No custom $global_result_class class found. Inherits from DBIx::Class::Core."; 
            $self->result_use_string("use parent 'DBIx::Class::Core';");
            $self->result_use_type('Core');
        };

        my $global_resultset_class = join '::' => $self->namespace, 'ResultSet';
        try {
            load $global_resultset_class;
            if($global_resultset_class->isa('DBIx::Class::Candy::ResultSet')) {
                $self->resultset_use_string("use $global_resultset_class");
                $self->resultset_use_type('Candy');
            }
            elsif($global_resultset_class->isa('DBIx::Class::ResultSet')) {
                $self->resultset_use_string("use parent '$global_resultset_class'");
                $self->resultset_use_type('Standard');
            }
            else {
                say "Note: No custom $global_resultset_class class found. Inherits from DBIx::Class::ResultSet."; 
                $self->resultset_use_string("use parent 'DBIx::Class::ResultSet'");
                $self->resultset_use_type('Core');
            }
        }
        catch {
            say "Note: No custom $global_resultset_class class found. Inherits from DBIx::Class::ResultSet."; 
            $self->resultset_use_string("use parent 'DBIx::Class::ResultSet';");
            $self->resultset_use_type('Core');
        };
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
