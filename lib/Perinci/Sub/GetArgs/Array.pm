package Perinci::Sub::GetArgs::Array;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_args_from_array);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
};

$SPEC{get_args_from_array} = {
    v => 1.1,
    summary => 'Get subroutine arguments (%args) from array',
    description => <<'_',

Using information in metadata's `args` property (particularly the `pos` and
`greedy` arg type clauses), extract arguments from an array into a hash
`\%args`, suitable for passing into subs.

Example:

    my $meta = {
        v => 1.1,
        summary => 'Multiply 2 numbers (a & b)',
        args => {
            a => {schema=>'num*', pos=>0},
            b => {schema=>'num*', pos=>1},
        }
    }

then `get_args_from_array(array=>[2, 3], meta=>$meta)` will produce:

    [200, "OK", {a=>2, b=>3}]

_
    args => {
        array => {
            schema => ['array*' => {}],
            req => 1,
            description => <<'_',

NOTE: array will be modified/emptied (elements will be taken from the array as
they are put into the resulting args). Copy your array first if you want to
preserve its content.

_
        },
        meta => {
            schema => ['hash*' => {}],
            req => 1,
        },
        meta_is_normalized => {
            summary => 'Can be set to 1 if your metadata is normalized, '.
                'to avoid duplicate effort',
            schema => 'bool',
            default => 0,
        },
        allow_extra_elems => {
            schema => ['bool' => {default=>0}],
            summary => 'Allow extra/unassigned elements in array',
            description => <<'_',

If set to 1, then if there are array elements unassigned to one of the arguments
(due to missing `pos`, for example), instead of generating an error, the
function will just ignore them.

_
        },
    },
};
sub get_args_from_array {
    my %fargs = @_;
    my $ary  = $fargs{array} or return [400, "Please specify array"];
    my $meta = $fargs{meta} or return [400, "Please specify meta"];
    unless ($fargs{meta_is_normalized}) {
        require Perinci::Sub::Normalize;
        $meta = Perinci::Sub::Normalize::normalize_function_metadata(
            $meta);
    }
    my $allow_extra_elems = $fargs{allow_extra_elems} // 0;

    my $rargs = {};

    my $args_p = $meta->{args} // {};
    for my $i (reverse 0..@$ary-1) {
        #$log->tracef("i=$i");
        while (my ($a, $as) = each %$args_p) {
            my $o = $as->{pos};
            if (defined($o) && $o == $i) {
                if ($as->{greedy}) {
                    my $type = $as->{schema}[0];
                    my @elems = splice(@$ary, $i);
                    if ($type eq 'array') {
                        $rargs->{$a} = \@elems;
                    } else {
                        $rargs->{$a} = join " ", @elems;
                    }
                    #$log->tracef("assign %s to arg->{$a}", $rargs->{$a});
                } else {
                    $rargs->{$a} = splice(@$ary, $i, 1);
                    #$log->tracef("assign %s to arg->{$a}", $rargs->{$a});
                }
            }
        }
    }

    return [400, "There are extra, unassigned elements in array: [".
                join(", ", @$ary)."]"] if @$ary && !$allow_extra_elems;

    [200, "OK", $rargs];
}

1;
#ABSTRACT:

=head1 SYNOPSIS

 use Perinci::Sub::GetArgs::Array;

 my $res = get_args_from_array(array=>\@ary, meta=>$meta, ...);


=head1 DESCRIPTION

This module provides get_args_from_array(). This module is used by, among
others, L<Perinci::Sub::GetArgs::Argv>.


=head1 SEE ALSO

L<Perinci>

=cut
