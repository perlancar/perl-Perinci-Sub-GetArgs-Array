package Sub::Spec::GetArgs::Array;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use Sub::Spec::Utils; # temp, for _parse_schema

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_args_from_array);

# VERSION

our %SPEC;

sub _parse_schema {
    Sub::Spec::Utils::_parse_schema(@_);
}

$SPEC{get_args_from_array} = {
    summary => 'Get subroutine arguments (%args) from array',
    description_fmt => 'org',
    description => <<'_',

Using information in sub spec's ~args~ clause (particularly the ~arg_pos~ and
~arg_greedy~ arg type clauses), extract arguments from an array into a hash
\%args, suitable for passing into subs.

Example:

: my $spec = {
:     summary => 'Multiply 2 numbers (a & b)',
:     args => {
:         a => ['num*' => {arg_pos=>0}],
:         b => ['num*' => {arg_pos=>1}],
:     }
: }

then ~get_args_from_array(array=>[2, 3], spec=>$spec)~ will produce:

: [200, "OK", {a=>2, b=>3}]

_
    args => {
        array => ['array*' => {
        }],
        spec => ['hash*' => {
        }],
        allow_extra_elems => ['bool' => {
            default => 0,
            summary => 'Allow extra/unassigned elements in array',
            description_fmt => 'org',
            description => <<'_',

If set to 1, then if there are array elements unassigned to one of the arguments
(due to missing ~arg_pos~, for example), instead of generating an error, the
function will just ignore them.

_
        }],
    },
};
sub get_args_from_array {
    my %input_args = @_;
    # don't assign this to $array, we have @array too, avoid error-prone
    $input_args{array} or return [400, "Please specify array"];
    my $sub_spec   = $input_args{spec};
    my $args_spec  = $input_args{_args_spec};
    if (!$args_spec) {
        $args_spec = $sub_spec->{args} // {};
        $args_spec = { map { $_ => _parse_schema($args_spec->{$_}) }
                           keys %$args_spec };
    }
    my $allow_extra_elems = $input_args{allow_extra_elems} // 0;
    return [400, "Please specify spec"] if !$sub_spec && !$args_spec;
    #$log->tracef("-> get_args_from_array(), array=%s", $array);

    my @array = @{$input_args{array}};
    my $args = {};

    for my $i (reverse 0..$#array) {
        #$log->tracef("i=$i");
        while (my ($name, $schema) = each %$args_spec) {
            my $schema = $args_spec->{$name};
            my $ah0 = $schema->{attr_hashes}[0];
            my $o = $ah0->{arg_pos};
            if (defined($o) && $o == $i) {
                if ($ah0->{arg_greedy}) {
                    $args->{$name} = [splice(@array, $i)];
                    #$log->tracef("assign %s to arg->{$name}", $args->{$name});
                } else {
                    $args->{$name} = splice(@array, $i, 1);
                    #$log->tracef("assign %s to arg->{$name}", $args->{$name});
                }
            }
        }
    }

    return [400, "There are extra, unassigned elements in array: [".
                join(", ", @array)."]"] if @array && !$allow_extra_elems;

    [200, "OK", $args];
}

1;
#ABSTRACT: Get subroutine arguments from array
__END__

=head1 SYNOPSIS

 use Sub::Spec::GetArgs::Array;

 my $res = get_args_from_array(array=>\@ary, spec=>$spec, ...);


=head1 DESCRIPTION

This module provides get_args_from_array() (and gencode_get_args_from_array(),
upcoming). This module is used by, among others, L<Sub::Spec::GetArgs::Argv> and
L<Sub::Spec::Wrapper>.

This module uses L<Log::Any> for logging framework.

This module's functions has L<Sub::Spec> specs.


=head1 FUNCTIONS

None are exported by default, but they are exportable.


=head1 SEE ALSO

L<Sub::Spec>

=cut
